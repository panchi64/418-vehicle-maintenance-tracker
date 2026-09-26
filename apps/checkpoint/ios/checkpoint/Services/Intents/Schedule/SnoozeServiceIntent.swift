//
//  SnoozeServiceIntent.swift
//  checkpoint
//
//  "Remind me about the oil change tomorrow." The voice version of a service
//  reminder's Remind Tomorrow button, with the same meaning: the reminder
//  comes back at 9 AM tomorrow and the schedule itself doesn't move
//  (`ServiceNotificationScheduler.snoozeRequest(for:vehicle:)`).
//
//  Only a service that is due — overdue, or inside the reminder lead time —
//  can be snoozed. The reminder rebuild keeps a snooze only while its service
//  is still due, so snoozing one that isn't would promise a reminder that
//  never arrives.
//

import AppIntents
import SwiftData

struct SnoozeServiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Remind Me Tomorrow"
    static let description = IntentDescription("Get a service's reminder again tomorrow morning")

    @Dependency var container: ModelContainer

    @Parameter(title: "Service", requestValueDialog: "Which service?")
    var service: ServiceEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Remind me about \(\.$service) tomorrow")
    }

    init() {}

    init(service: ServiceEntity) {
        self.service = service
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = container.mainContext
        let service = try IntentStore.service(self.service, in: context)
        let vehicle = try IntentStore.vehicle(of: service)

        guard Self.canSnooze(service, on: vehicle) else {
            return .result(dialog: IntentDialog(stringLiteral: L10n.siriSnoozeNotDue(service: service.name)))
        }
        await NotificationService.shared.addSnooze(
            ServiceNotificationScheduler.snoozeRequest(for: service, vehicle: vehicle)
        )
        return .result(dialog: IntentDialog(stringLiteral: L10n.siriSnoozeSaved(service: service.name)))
    }

    @MainActor
    static func canSnooze(_ service: Service, on vehicle: Vehicle, now: Date = .now) -> Bool {
        ServiceNotificationScheduler.stillDueServiceIDs(for: vehicle, now: now).contains(service.id.uuidString)
    }
}
