//
//  ReminderIntents.swift
//  checkpoint
//
//  The iOS 27 Reminders schema intents, over `ServiceReminderEntity` and
//  `VehicleListEntity`. Each writes through the path its iOS 26 twin uses —
//  `ServiceScheduling` (Add Service), `Service.apply` (Edit Service),
//  `ServiceLogging.markDone` (Mark Service Done), `DeleteServiceIntent.delete`
//  and `VehicleService` — and asks before the same things they ask before.
//
//  Create, update and delete overlap Add / Edit / Mark Done / Delete Service,
//  so they are `isAssistantOnly`: Siri uses them, Shortcuts keeps listing
//  the originals once (Apple's guidance for a schema intent that duplicates
//  an existing one). Create List has no twin and shows in Shortcuts.
//
//  Sections are skipped (Reminders isn't an all-or-nothing domain).
//  Flags, tags, URLs, images and location triggers are accepted and ignored.
//

import AppIntents
import SwiftData
// The schema macro's `images` parameter names `UTType.image`.
import UniformTypeIdentifiers

// MARK: - Create

@available(iOS 27, *)
@AppIntent(schema: .reminders.createReminder)
struct CreateServiceReminderIntent {
    static let isAssistantOnly = true

    @Dependency var container: ModelContainer

    var title: String
    var list: VehicleListEntity?
    var note: AttributedString?
    var isFlagged: Bool?
    var images: [IntentFile]
    var tags: Set<String>
    var urls: [URL]
    var dueDate: DateComponents?
    var recurrence: Calendar.RecurrenceRule?
    var locationTrigger: NoLocationTriggerEntity?
    var section: NoSectionEntity?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ServiceReminderEntity> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(id: list?.id, in: context)

        switch Self.add(
            title: title,
            note: note.map { String($0.characters) },
            dueDate: dueDate,
            recurrence: recurrence,
            to: vehicle,
            in: context
        ) {
        case .needsDue:
            throw IntentError.serviceNeedsDue
        case .alreadyScheduled(let existing):
            return .result(
                value: ServiceReminderEntity(model: existing),
                dialog: IntentDialog(stringLiteral: L10n.siriAddExists(
                    service: existing.name,
                    vehicle: vehicle.displayName,
                    due: SpokenValue.schedule(dueDate: existing.dueDate, dueMileage: existing.dueMileage) ?? ""
                ))
            )
        case .added(let service):
            try IntentStore.commit(vehicle, in: context)
            return .result(
                value: ServiceReminderEntity(model: service),
                dialog: IntentDialog(stringLiteral: L10n.siriAddSaved(
                    service: service.name,
                    vehicle: vehicle.displayName,
                    due: SpokenValue.schedule(dueDate: service.dueDate, dueMileage: service.dueMileage) ?? ""
                ))
            )
        }
    }

    /// The write: Add Service's scheduling, with the reminder's due date and
    /// recurrence as the spoken due and cadence, and its note as the notes.
    @MainActor
    static func add(
        title: String,
        note: String?,
        dueDate: DateComponents?,
        recurrence: Calendar.RecurrenceRule?,
        to vehicle: Vehicle,
        in context: ModelContext,
        now: Date = .now
    ) -> ServiceScheduling.Outcome {
        let outcome = ServiceScheduling.add(
            named: title.trimmingCharacters(in: .whitespacesAndNewlines),
            to: vehicle,
            request: ServiceScheduling.Request(
                intervalMonths: recurrence.flatMap(ReminderMapping.intervalMonths(from:)),
                dueDate: dueDate.flatMap { ReminderMapping.dueDate(from: $0, now: now) }
            ),
            in: context,
            now: now
        )
        if case .added(let service) = outcome, let note {
            service.notes = ReminderMapping.notes(fromReminderNote: note, mileageSummary: nil)
        }
        return outcome
    }
}

// MARK: - Update

@available(iOS 27, *)
@AppIntent(schema: .reminders.updateReminder)
struct UpdateServiceReminderIntent {
    static let isAssistantOnly = true

    @Dependency var container: ModelContainer

    var target: ServiceReminderEntity
    var title: String?
    var note: AttributedString?
    var tags: Set<String>?
    var urls: [URL]?
    var dueDate: DateComponents?
    var recurrence: Calendar.RecurrenceRule?
    var isCompleted: Bool?
    var isFlagged: Bool?
    var list: VehicleListEntity?
    var locationTrigger: NoLocationTriggerEntity?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ServiceReminderEntity> & ProvidesDialog {
        let context = container.mainContext
        let service = try IntentStore.service(id: target.id, in: context)
        let vehicle = try IntentStore.vehicle(of: service)
        if let list, list.id != vehicle.id { throw IntentError.serviceCannotMove }

        // Completing logs history, so it is confirmed first, as Mark Service
        // Done is, before anything is written. Un-completing has no meaning
        // for a service: the history entry stays.
        let completes = isCompleted == true && service.hasDueTracking
        if completes {
            try await requestConfirmation(
                actionName: .log,
                dialog: IntentDialog(stringLiteral: L10n.siriDoneConfirm(service: service.name, vehicle: vehicle.displayName)),
                snippetIntent: ServiceRecordSnippetIntent(
                    serviceNames: [service.name],
                    vehicleName: vehicle.displayName,
                    occasion: ServiceLogging.Occasion(),
                    vehicle: vehicle
                )
            )
        }

        Self.apply(update, completing: completes, to: service, on: vehicle, in: context)
        try IntentStore.commit(vehicle, in: context)

        let dialog: String
        if completes {
            dialog = MarkServiceDoneIntent.savedDialog(for: service, vehicle: vehicle)
        } else {
            dialog = SpokenValue.schedule(dueDate: service.dueDate, dueMileage: service.dueMileage)
                .map { L10n.siriEditSaved(service: service.name, due: $0) }
                ?? L10n.siriEditSavedUnscheduled(service: service.name)
        }
        return .result(value: ServiceReminderEntity(model: service), dialog: IntentDialog(stringLiteral: dialog))
    }

    var update: ReminderMapping.Update {
        ReminderMapping.Update(
            title: title,
            note: note.map { String($0.characters) },
            dueDate: dueDate,
            recurrence: recurrence
        )
    }

    /// The write, once confirmed: the field edits, then — when completing —
    /// Mark Service Done's log for today at the reading on file.
    @MainActor
    static func apply(
        _ update: ReminderMapping.Update,
        completing: Bool,
        to service: Service,
        on vehicle: Vehicle,
        in context: ModelContext,
        now: Date = .now
    ) {
        let edit = ReminderMapping.edit(of: service, applying: update, now: now)
        if edit != service.unchangedEdit {
            service.apply(edit)
        }
        if completing {
            ServiceLogging.markDone(service, on: vehicle, occasion: ServiceLogging.Occasion(), in: context, now: now)
        }
    }
}

// MARK: - Delete

@available(iOS 27, *)
@AppIntent(schema: .reminders.deleteReminders)
struct DeleteServiceRemindersIntent: DeleteIntent {
    static let isAssistantOnly = true

    @Dependency var container: ModelContainer

    var entities: [ServiceReminderEntity]

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = container.mainContext
        let services = try IntentStore.services(ids: entities.map(\.id), in: context)
        guard !services.isEmpty else { throw IntentError.serviceNotFound }
        let names = services.map(\.name)

        try await requestConfirmation(dialog: IntentDialog(stringLiteral: L10n.siriDeleteServiceConfirm(names)))

        try DeleteServiceIntent.delete(services, in: context)
        return .result(dialog: IntentDialog(stringLiteral: L10n.siriDeleteServiceDone(names)))
    }
}

// MARK: - Create list

@available(iOS 27, *)
@AppIntent(schema: .reminders.createList)
struct CreateVehicleListIntent {
    @Dependency var container: ModelContainer

    var type: ReminderListType
    var name: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<VehicleListEntity> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try Self.addVehicle(named: name, in: context, isPro: StoreManager.shared.isPro)
        try IntentStore.commit(vehicle, in: context)
        return .result(
            value: VehicleListEntity(model: vehicle),
            dialog: IntentDialog(stringLiteral: L10n.siriVehicleAdded(vehicle.displayName))
        )
    }

    /// A new vehicle by name, as Add Vehicle saves one, within the free
    /// limit unless Pro. Make, model and odometer are left for the app.
    @MainActor
    static func addVehicle(named name: String, in context: ModelContext, isPro: Bool) throws -> Vehicle {
        try AddVehicleIntent.checkLimit(in: context, isPro: isPro)
        var fields = VehicleFields()
        fields.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return VehicleService.create(fields, in: context)
    }
}
