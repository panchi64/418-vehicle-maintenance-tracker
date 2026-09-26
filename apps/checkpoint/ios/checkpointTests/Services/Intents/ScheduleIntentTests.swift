//
//  ScheduleIntentTests.swift
//  checkpointTests
//
//  Adding, editing, snoozing, stopping and deleting services by voice. The
//  deletes and Stop Tracking never write before Siri hears a yes.
//

import XCTest
import AppIntents
import SwiftData
import UserNotifications
@testable import checkpoint

final class ScheduleIntentTests: IntentTestCase {

    // MARK: - Add

    func test_add_preset_takesItsCadenceFromToday() throws {
        guard case .added(let service) = ServiceScheduling.add(
            named: "tire rotation", to: vehicle, request: .init(), in: context
        ) else { return XCTFail("Expected the service to be added") }

        let preset = try XCTUnwrap(PresetDataService.shared.loadPresets().first { $0.name == "Tire Rotation" })
        XCTAssertEqual(service.name, "Tire Rotation")
        XCTAssertEqual(service.intervalMonths, preset.defaultIntervalMonths)
        XCTAssertTrue(service.isRecurring)
        if let miles = preset.defaultIntervalMiles {
            XCTAssertEqual(service.dueMileage, 45_000 + miles, "Projected from the reading on file")
        }
        XCTAssertTrue(service.hasDueTracking)
    }

    func test_add_spokenIntervalAndDate_winOverThePreset() {
        let due = Calendar.current.date(byAdding: .day, value: 20, to: .now)!
        guard case .added(let service) = ServiceScheduling.add(
            named: "Oil Change", to: vehicle,
            request: .init(intervalMonths: 4, dueDate: due), in: context
        ) else { return XCTFail("Expected the service to be added") }

        XCTAssertEqual(service.intervalMonths, 4)
        XCTAssertEqual(service.dueDate, due)
    }

    func test_add_freeTextWithoutWhen_needsADueDate() {
        guard case .needsDue = ServiceScheduling.add(
            named: "Detailing", to: vehicle, request: .init(), in: context
        ) else { return XCTFail("Expected Siri to ask when it is due") }
        XCTAssertTrue(services.isEmpty)
    }

    func test_add_alreadyTracked_doesNotDuplicate() {
        let oil = addService("Oil Change")
        guard case .alreadyScheduled(let existing) = ServiceScheduling.add(
            named: "oil change", to: vehicle, request: .init(), in: context
        ) else { return XCTFail("Expected the existing service") }
        XCTAssertEqual(existing.id, oil.id)
        XCTAssertEqual(services.count, 1)
    }

    func test_addServiceIntent_perform_savesAndAnswers() async throws {
        let intent = AddServiceIntent()
        intent.name = "Coolant Flush"

        let result = try await wired(intent).perform()

        XCTAssertEqual(result.value?.name, "Coolant Flush")
        XCTAssertEqual(services.count, 1)
        XCTAssertFalse(context.hasChanges)
    }

    // MARK: - Edit

    func test_edit_interval_turnsRepeatOn_andKeepsWhatWasNotSaid() {
        let wipers = addService("Wiper Blades", dueInDays: 40, intervalMonths: nil, intervalMiles: nil, isRecurring: false)
        let dueBefore = wipers.dueDate
        let intent = EditServiceIntent()
        intent.intervalMonths = 12

        let edit = EditServiceIntent.edit(of: wipers, applying: intent)
        wipers.apply(edit)

        XCTAssertEqual(wipers.intervalMonths, 12)
        XCTAssertTrue(wipers.isRecurring)
        XCTAssertEqual(wipers.dueDate, dueBefore, "An explicit due date on file wins over the new cadence, as in the form")
        XCTAssertEqual(wipers.name, "Wiper Blades")
    }

    func test_edit_nothingSaid_isNoChange() {
        let oil = addService()
        XCTAssertEqual(EditServiceIntent.edit(of: oil, applying: EditServiceIntent()), oil.unchangedEdit)
    }

    func test_editServiceIntent_perform_movesDueMileage() async throws {
        let oil = addService(dueInDays: nil, dueMileage: 50_000)
        try context.save()
        let intent = EditServiceIntent()
        intent.service = ServiceEntity(model: oil)
        intent.dueMileage = 52_000

        _ = try await wired(intent).perform()

        XCTAssertEqual(oil.dueMileage, 52_000)
        XCTAssertFalse(context.hasChanges)
    }

    // MARK: - Snooze

    func test_canSnooze_onlyServicesStillDue() {
        let overdue = addService("Oil Change", dueInDays: -3)
        let farOff = addService("Coolant Flush", dueInDays: 200)
        XCTAssertTrue(SnoozeServiceIntent.canSnooze(overdue, on: vehicle))
        XCTAssertFalse(SnoozeServiceIntent.canSnooze(farOff, on: vehicle))
    }

    func test_snoozeRequest_matchesTheBannerButton() throws {
        let oil = addService("Oil Change", dueInDays: -3)
        let now = Date()
        let request = ServiceNotificationScheduler.snoozeRequest(for: oil, vehicle: vehicle, now: now)

        XCTAssertTrue(ServiceNotificationScheduler.isSnoozeID(request.identifier))
        XCTAssertTrue(request.identifier.hasPrefix(ServiceNotificationScheduler.requestPrefix))
        XCTAssertEqual(request.content.userInfo["serviceID"] as? String, oil.id.uuidString)
        XCTAssertEqual(request.content.categoryIdentifier, NotificationService.serviceDueCategoryID)
        XCTAssertEqual(request.content.title, ServiceReminderCopy.snoozeTitle(serviceNames: ["Oil Change"]))

        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        XCTAssertEqual(trigger.dateComponents.day, Calendar.current.component(.day, from: tomorrow))
        XCTAssertEqual(trigger.dateComponents.hour, NotificationHelpers.defaultHour)
        XCTAssertTrue(
            ServiceNotificationScheduler.isKeptSnooze(request, keptServiceIDs: [oil.id.uuidString]),
            "The next reminder rebuild keeps it while the service is due"
        )
    }

    func test_snoozeIntent_notDue_saysSo() async throws {
        let farOff = addService("Coolant Flush", dueInDays: 200)
        try context.save()

        _ = try await wired(SnoozeServiceIntent(service: ServiceEntity(model: farOff))).perform()

        let pending = await ServiceNotificationScheduler.getPendingNotifications()
        XCTAssertFalse(pending.contains { $0.identifier.contains(farOff.id.uuidString) }, "Nothing is snoozed")
        XCTAssertTrue(farOff.hasDueTracking, "Snoozing never moves the schedule")
    }

    // MARK: - Stop tracking

    func test_stopTracking_neverWritesWithoutAnAnswer() async throws {
        let oil = addService()
        try context.save()
        let intent = StopTrackingServiceIntent()
        intent.service = ServiceEntity(model: oil)

        await runUnanswered { _ = try await self.wired(intent).perform() }

        XCTAssertTrue(oil.hasDueTracking)
    }

    // MARK: - Delete

    func test_deleteService_neverDeletesWithoutAnAnswer() async throws {
        let oil = addService()
        try context.save()

        await runUnanswered { _ = try await self.wired(DeleteServiceIntent(entities: [ServiceEntity(model: oil)])).perform() }

        XCTAssertEqual(services.count, 1)
    }

    func test_deleteService_afterYes_removesServiceAndHistory() throws {
        let oil = addService()
        addLog(for: oil, daysAgo: 100)
        let keep = addService("Coolant Flush")
        try context.save()

        try DeleteServiceIntent.delete([oil], in: context)

        XCTAssertEqual(services.map(\.id), [keep.id])
        XCTAssertTrue(logs.isEmpty, "History goes with the service")
        XCTAssertFalse(context.hasChanges)
    }

    func test_deleteServiceLog_neverDeletesWithoutAnAnswer() async throws {
        let log = addLog(for: addService(), daysAgo: 30)
        try context.save()

        await runUnanswered { _ = try await self.wired(DeleteServiceLogIntent(entities: [ServiceLogEntity(model: log)])).perform() }

        XCTAssertEqual(logs.count, 1)
    }

    func test_deleteServiceLog_afterYes_removesOnlyThatEntry() throws {
        let oil = addService()
        let old = addLog(for: oil, daysAgo: 300)
        let recent = addLog(for: oil, daysAgo: 30)
        try context.save()

        try DeleteServiceLogIntent.delete([old], in: context)

        XCTAssertEqual(logs.map(\.id), [recent.id])
        XCTAssertEqual(services.count, 1, "The service stays")
    }
}
