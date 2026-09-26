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
