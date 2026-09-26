//
//  IntentStore.swift
//  checkpoint
//
//  How an intent turns the entities Siri resolved back into models, and how
//  it finishes a write. Every intent resolves and commits through here, so a
//  write from Siri leaves the app exactly where the same edit made in-app
//  would: saved, reminders rebuilt, icon and widget current, Spotlight
//  following.
//

import AppIntents
import SwiftData

/// What an intent says when it can't go on. Spoken, so each case names the
/// next step rather than the failure.
nonisolated enum IntentError: Error, Equatable, CustomLocalizedStringResourceConvertible {
    case noVehicles
    case vehicleNotFound
    case serviceNotFound
    case serviceLogNotFound
    case visitNotFound
    case documentNotFound
    /// A free user already keeps `VehicleService.freeVehicleLimit` vehicles.
    case vehicleLimitReached
    /// A new service with no due date, mileage or cadence would never come due.
    case serviceNeedsDue
    /// A service's history belongs to its vehicle; it can't be re-homed.
    case serviceCannotMove
    /// Nothing in the files handed over was an image.
    case noImages
    /// A receipt with nothing readable on it.
    case receiptUnreadable
    /// A Visual Intelligence result tapped after its capture was dropped.
    case captureExpired
    /// Recalls are looked up by make, model and year.
    case recallsNeedIdentity
    /// NHTSA couldn't be reached and nothing was cached.
    case recallsUnavailable
    /// Renewing needs a marbete month on file.
    case noMarbete
    /// Find Document matched nothing.
    case noMatchingDocument
    /// Add Document was handed something that is neither an image nor a PDF.
    case unsupportedDocument
    /// A vehicle with no service history has nothing to export.
    case nothingToExport
    case exportFailed
    case appointmentNotFound
    /// A booking needs a shop to be named by.
    case appointmentNeedsShop
    /// Reschedule or cancel with nothing booked.
    case noAppointments
    /// Only a scheduled visit can be moved or cancelled.
    case appointmentClosed
    /// An appointment belongs to its vehicle; it can't be re-homed.
    case appointmentCannotMove
    case noteNotFound
    /// A note belongs to its vehicle; it can't be re-homed.
    case noteCannotMove
    /// A note with no title and no text.
    case noteNeedsText
    /// Find Note matched nothing.
    case noMatchingNote

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noVehicles: "Add a vehicle in Checkpoint first."
        case .vehicleNotFound: "That vehicle is no longer in Checkpoint."
        case .serviceNotFound: "That service is no longer in Checkpoint."
        case .serviceLogNotFound: "That service log is no longer in Checkpoint."
        case .visitNotFound: "That visit is no longer in Checkpoint."
        case .documentNotFound: "That document is no longer in Checkpoint."
        case .vehicleLimitReached: "Adding more vehicles needs Checkpoint Pro. Open Checkpoint to upgrade."
        case .serviceNeedsDue: "Say when it's due, with a date or how often it repeats."
        case .serviceCannotMove: "A service can't move to another vehicle. Add it to that vehicle instead."
        case .noImages: "Checkpoint can only save images here."
        case .receiptUnreadable: "Checkpoint couldn't read that receipt. Try a sharper photo, or log it in the app."
        case .captureExpired: "That capture is no longer available. Try Visual Intelligence again."
        case .recallsNeedIdentity: "Add this vehicle's make, model and year in Checkpoint to check its recalls."
        case .recallsUnavailable: "Checkpoint couldn't reach NHTSA to check recalls. Try again later."
        case .noMarbete: "There's no marbete date for this vehicle. Add it in Edit Vehicle first."
        case .noMatchingDocument: "Checkpoint has no document like that. Add it from the Documents library."
        case .unsupportedDocument: "Checkpoint can save photos and PDFs as documents."
        case .nothingToExport: "There's no service history to export yet."
        case .exportFailed: "Checkpoint couldn't create the PDF. Try exporting from the Services tab."
        case .appointmentNotFound: "That appointment is no longer in Checkpoint."
        case .appointmentNeedsShop: "Say which shop the appointment is at."
        case .noAppointments: "There's no shop appointment booked. Book one in Checkpoint first."
        case .appointmentClosed: "That appointment is already completed or cancelled."
        case .appointmentCannotMove: "An appointment can't move to another vehicle. Book one for that vehicle instead."
        case .noteNotFound: "That note is no longer in Checkpoint."
        case .noteCannotMove: "A note can't move to another vehicle. Add it to that vehicle instead."
        case .noteNeedsText: "Say what the note should say."
        case .noMatchingNote: "Checkpoint has no note like that."
        }
    }
}

@MainActor
enum IntentStore {

    /// The vehicle `entity` names, or — when the phrase named none — the one
    /// the app has selected, so "update mileage" means the car on screen.
    /// Falls back to the first vehicle before any selection is persisted.
    static func vehicle(
        for entity: VehicleEntity?,
        in context: ModelContext,
        defaults: UserDefaults = .standard
    ) throws -> Vehicle {
        try vehicle(id: entity?.id, in: context, defaults: defaults)
    }

    /// `vehicle(for:)` by ID, for entity types other than `VehicleEntity`
    /// that stand for a vehicle (the iOS 27 list and album schema types).
    static func vehicle(
        id: UUID?,
        in context: ModelContext,
        defaults: UserDefaults = .standard
    ) throws -> Vehicle {
        if let id {
            guard let vehicle = try VehicleEntity.models(ids: [id], in: context).first else {
                throw IntentError.vehicleNotFound
            }
            return vehicle
        }
        let vehicles = try VehicleEntity.models(ids: nil, in: context)
        guard !vehicles.isEmpty else { throw IntentError.noVehicles }
        let selectedID = defaults.string(forKey: AppGroupConstants.appSelectedVehicleIDKey)
        return vehicles.first { $0.id.uuidString == selectedID } ?? vehicles[0]
    }

    static func service(_ entity: ServiceEntity, in context: ModelContext) throws -> Service {
        try service(id: entity.id, in: context)
    }

    static func service(id: UUID, in context: ModelContext) throws -> Service {
        guard let service = try ServiceEntity.models(ids: [id], in: context).first else {
            throw IntentError.serviceNotFound
        }
        return service
    }

    static func services(_ entities: [ServiceEntity], in context: ModelContext) throws -> [Service] {
        try services(ids: entities.map(\.id), in: context)
    }

    static func services(ids: [UUID], in context: ModelContext) throws -> [Service] {
        let services = try ServiceEntity.models(ids: ids, in: context)
        guard !services.isEmpty || ids.isEmpty else { throw IntentError.serviceNotFound }
        return services
    }

    static func document(id: UUID, in context: ModelContext) throws -> Document {
        guard let document = try DocumentEntity.models(ids: [id], in: context).first else {
            throw IntentError.documentNotFound
        }
        return document
    }

    static func appointment(id: UUID, in context: ModelContext) throws -> Appointment {
        guard let appointment = try AppointmentEntity.models(ids: [id], in: context).first else {
            throw IntentError.appointmentNotFound
        }
        return appointment
    }

    /// A scheduled appointment by ID — the only kind that can be moved or
    /// cancelled.
    static func scheduledAppointment(id: UUID, in context: ModelContext) throws -> Appointment {
        let appointment = try appointment(id: id, in: context)
        guard appointment.isScheduled else { throw IntentError.appointmentClosed }
        return appointment
    }

    static func note(id: UUID, in context: ModelContext) throws -> VehicleNote {
        guard let note = try VehicleNoteEntity.models(ids: [id], in: context).first else {
            throw IntentError.noteNotFound
        }
        return note
    }

    static func logs(_ entities: [ServiceLogEntity], in context: ModelContext) throws -> [ServiceLog] {
        let logs = try ServiceLogEntity.models(ids: entities.map(\.id), in: context)
        guard !logs.isEmpty || entities.isEmpty else { throw IntentError.serviceLogNotFound }
        return logs
    }

    /// The vehicle a service belongs to. A service always has one in practice;
    /// an orphan (mid-delete sync) has nowhere to be logged.
    static func vehicle(of service: Service) throws -> Vehicle {
        guard let vehicle = service.vehicle else { throw IntentError.serviceNotFound }
        return vehicle
    }

    /// Finish a write: save, then refresh everything computed from the
    /// vehicle's schedules. Saving explicitly matters here — an intent can
    /// return and the process suspend before autosave runs.
    static func commit(_ vehicle: Vehicle, in context: ModelContext) throws {
        DerivedSurfaces.refresh(for: vehicle)
        try save(context)
    }

    /// Save and let Spotlight follow, for writes whose action already
    /// refreshed the derived surfaces (`ServiceDeleteAction`,
    /// `ServiceLogDeleteAction`).
    static func save(_ context: ModelContext) throws {
        try context.save()
        SpotlightIndexer.shared.scheduleReindex(from: context.container)
    }
}
