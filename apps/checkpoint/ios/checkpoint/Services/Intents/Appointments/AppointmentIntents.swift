//
//  AppointmentIntents.swift
//  checkpoint
//
//  Shop appointments by voice (iOS 26, every tier):
//    "Book the Civic at Firestone Friday at 9 in Checkpoint"  Schedule
//    "Move my Firestone appointment to Monday"                Reschedule
//    "Cancel my shop appointment"                             Cancel (asks)
//
//  All three write through `AppointmentService`, the path the appointment
//  sheet uses, and commit through `IntentStore`. Booking and moving are
//  additive or undoable in-app, so they don't ask; cancelling asks first
//  (voice deletes are limited, and a cancel is the voice-reachable one here).
//  On iOS 27 the Calendar schema twins (`Schema/Calendar/`) reach the same
//  functions.
//

import AppIntents
import SwiftData

// MARK: - Schedule

struct ScheduleAppointmentIntent: AppIntent {
    static let title: LocalizedStringResource = "Schedule Shop Appointment"
    static let description = IntentDescription("Book a visit at a shop for a vehicle. Checkpoint reminds you the day before and an hour before.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Shop", requestValueDialog: "Which shop?")
    var shop: String

    @Parameter(title: "Date and Time", requestValueDialog: "When is the appointment?")
    var date: Date

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    @Parameter(title: "Services", description: "Tracked services the visit is for.")
    var services: [ServiceEntity]?

    @Parameter(title: "Address")
    var address: String?

    @Parameter(title: "Note", description: "What to ask or remember at the shop.")
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Book \(\.$vehicle) at \(\.$shop) on \(\.$date)") {
            \.$services
            \.$address
            \.$note
        }
    }

    init() {}

    init(vehicle: VehicleEntity?, shop: String) {
        self.vehicle = vehicle
        self.shop = shop
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<AppointmentEntity> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        let appointment = try Self.book(
            AppointmentFields(
                shopName: shop,
                startDate: date,
                address: address ?? "",
                note: note ?? "",
                serviceIDs: (services ?? []).map(\.id)
            ),
            on: vehicle,
            in: context
        )
        return .result(
            value: AppointmentEntity(model: appointment),
            dialog: IntentDialog(stringLiteral: L10n.siriAppointmentBooked(
                vehicle: vehicle.displayName,
                shop: appointment.shopName,
                date: SpokenValue.date(appointment.startDate),
                time: SpokenValue.time(appointment.startDate)
            ))
        )
    }

    /// The write: validate, book, commit.
    @MainActor
    static func book(_ fields: AppointmentFields, on vehicle: Vehicle, in context: ModelContext) throws -> Appointment {
        guard fields.isValid else { throw IntentError.appointmentNeedsShop }
        let appointment = AppointmentService.schedule(fields, on: vehicle, in: context)
        try IntentStore.commit(vehicle, in: context)
        return appointment
    }
}

// MARK: - Reschedule

struct RescheduleAppointmentIntent: AppIntent {
    static let title: LocalizedStringResource = "Reschedule Shop Appointment"
    static let description = IntentDescription("Move a booked shop visit to a new date and time. Its reminders move with it.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Appointment", description: "Leave empty for the next one on the vehicle Checkpoint is showing.")
    var appointment: AppointmentEntity?

    @Parameter(title: "New Date and Time", requestValueDialog: "When should it be?")
    var date: Date

    static var parameterSummary: some ParameterSummary {
        Summary("Move \(\.$appointment) to \(\.$date)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<AppointmentEntity> & ProvidesDialog {
        let context = container.mainContext
        let target = try AppointmentResolution.target(appointment?.id, in: context)
        try Self.move(target, to: date, in: context)
        return .result(
            value: AppointmentEntity(model: target),
            dialog: IntentDialog(stringLiteral: L10n.siriAppointmentMoved(
                vehicle: target.vehicle?.displayName ?? "",
                shop: target.shopName,
                date: SpokenValue.date(target.startDate),
                time: SpokenValue.time(target.startDate)
            ))
        )
    }

    @MainActor
    static func move(_ appointment: Appointment, to date: Date, in context: ModelContext) throws {
        guard appointment.isScheduled else { throw IntentError.appointmentClosed }
        AppointmentService.reschedule(appointment, to: date)
        try AppointmentResolution.commit(appointment, in: context)
    }
}

// MARK: - Cancel

struct CancelAppointmentIntent: AppIntent {
    static let title: LocalizedStringResource = "Cancel Shop Appointment"
    static let description = IntentDescription("Cancel a booked shop visit and its reminders. Checkpoint asks first.")

    @Dependency var container: ModelContainer

    @Parameter(title: "Appointment", description: "Leave empty for the next one on the vehicle Checkpoint is showing.")
    var appointment: AppointmentEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Cancel \(\.$appointment)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = container.mainContext
        let target = try AppointmentResolution.target(appointment?.id, in: context)
        let vehicleName = target.vehicle?.displayName ?? ""
        try await requestConfirmation(
            dialog: IntentDialog(stringLiteral: L10n.siriAppointmentCancelAsk(
                vehicle: vehicleName,
                shop: target.shopName,
                date: SpokenValue.date(target.startDate),
                time: SpokenValue.time(target.startDate)
            ))
        )
        try Self.cancel(target, in: context)
        return .result(dialog: IntentDialog(stringLiteral: L10n.siriAppointmentCancelled(
            vehicle: vehicleName,
            shop: target.shopName
        )))
    }

    /// The write, once confirmed.
    @MainActor
    static func cancel(_ appointment: Appointment, in context: ModelContext) throws {
        guard appointment.isScheduled else { throw IntentError.appointmentClosed }
        AppointmentService.cancel(appointment)
        try AppointmentResolution.commit(appointment, in: context)
    }
}

// MARK: - Shared

@MainActor
enum AppointmentResolution {
    /// The appointment an intent means: the one named, or — when the phrase
    /// named none — the next scheduled one on the vehicle Checkpoint is
    /// showing, else the next one anywhere.
    static func target(
        _ id: UUID?,
        in context: ModelContext,
        defaults: UserDefaults = .standard
    ) throws -> Appointment {
        if let id { return try IntentStore.scheduledAppointment(id: id, in: context) }
        let vehicle = try? IntentStore.vehicle(id: nil, in: context, defaults: defaults)
        if let next = Appointment.scheduled(vehicle?.appointments ?? []).first { return next }
        let all = try context.fetch(FetchDescriptor<Appointment>())
        guard let next = Appointment.scheduled(all).first else { throw IntentError.noAppointments }
        return next
    }

    /// Finish a write: commit through the appointment's vehicle, or a plain
    /// save for an orphan (mid-delete sync).
    static func commit(_ appointment: Appointment, in context: ModelContext) throws {
        if let vehicle = appointment.vehicle {
            try IntentStore.commit(vehicle, in: context)
        } else {
            try IntentStore.save(context)
        }
    }
}
