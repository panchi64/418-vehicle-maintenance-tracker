//
//  RemindTomorrowTests.swift
//  checkpointTests
//
//  "Remind Tomorrow" on service and marbete reminders. The snooze is built
//  from the delivered notification alone, and a vehicle rebuild must not
//  sweep it away while its services are still due. Asserts on built requests
//  and keep/drop decisions — the test host has no notification authorization,
//  so pending-center state can't be observed.
//

import XCTest
import UserNotifications
@testable import checkpoint

@MainActor
final class RemindTomorrowTests: XCTestCase {

    private let now = Date()

    private func dueIn(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: now)!
    }

    private func delivered(_ services: [Service], vehicle: Vehicle, daysBeforeDue: Int = 0) -> UNNotificationRequest {
        let bundle = ServiceReminderBundle(
            daysBeforeDue: daysBeforeDue,
            notificationDate: now,
            occurrences: services.map {
                ServiceReminderOccurrence(
                    serviceID: $0.id, serviceName: $0.name, daysBeforeDue: daysBeforeDue, notificationDate: now
                )
            }
        )
        return ServiceNotificationScheduler.buildNotificationRequest(for: bundle, vehicle: vehicle)
    }

    private func assertFiresTomorrowAtNine(_ request: UNNotificationRequest, file: StaticString = #filePath, line: UInt = #line) {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            return XCTFail("Snooze should use a calendar trigger", file: file, line: line)
        }
        let tomorrow = Calendar.current.dateComponents([.year, .month, .day], from: dueIn(1))
        XCTAssertEqual(trigger.dateComponents.year, tomorrow.year, file: file, line: line)
        XCTAssertEqual(trigger.dateComponents.month, tomorrow.month, file: file, line: line)
        XCTAssertEqual(trigger.dateComponents.day, tomorrow.day, file: file, line: line)
        XCTAssertEqual(trigger.dateComponents.hour, NotificationHelpers.defaultHour, file: file, line: line)
    }

    // MARK: - Service snooze

    func testSingleServiceSnoozeRewordsWithoutLeadTime() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let oil = Service(name: "Oil Change", dueDate: now)
        let original = delivered([oil], vehicle: vehicle)

        let snooze = ServiceNotificationScheduler.snoozeRequest(for: original, now: now)!

        XCTAssertEqual(snooze.content.title, "Oil Change Reminder")
        XCTAssertEqual(snooze.content.body, "My Car - Oil Change is due for maintenance")
        XCTAssertEqual(snooze.content.categoryIdentifier, NotificationService.serviceDueCategoryID)
        XCTAssertEqual(snooze.identifier, original.identifier + "-snooze")
        XCTAssertTrue(snooze.identifier.hasPrefix(ServiceNotificationScheduler.requestPrefix))
        assertFiresTomorrowAtNine(snooze)
    }

    func testBundleSnoozeKeepsEveryServiceOnTheBanner() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let services = [Service(name: "Oil Change"), Service(name: "Tire Rotation")]
        let original = delivered(services, vehicle: vehicle)

        let snooze = ServiceNotificationScheduler.snoozeRequest(for: original, now: now)!

        XCTAssertEqual(snooze.content.title, "Reminder: 2 services")
        XCTAssertTrue(snooze.content.body.contains("Oil Change"))
        XCTAssertTrue(snooze.content.body.contains("Tire Rotation"))
        XCTAssertEqual(
            Set(ServiceNotificationScheduler.referencedServiceIDs(in: snooze.content.userInfo)),
            Set(services.map(\.id.uuidString))
        )
    }

    func testSnoozingASnoozeReplacesItInsteadOfStacking() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let first = ServiceNotificationScheduler.snoozeRequest(
            for: delivered([Service(name: "Oil Change")], vehicle: vehicle), now: now
        )!

        let second = ServiceNotificationScheduler.snoozeRequest(for: first, now: now)!

        XCTAssertEqual(second.identifier, first.identifier)
    }

    func testLegacyPayloadWithoutNamesIsRedeliveredAsIs() {
        let content = UNMutableNotificationContent()
        content.title = "Oil Change due today"
        content.body = "My Car - Oil Change"
        content.userInfo = ["serviceIDs": [UUID().uuidString], "vehicleID": UUID().uuidString]
        let original = UNNotificationRequest(identifier: "service-legacy", content: content, trigger: nil)

        let snooze = ServiceNotificationScheduler.snoozeRequest(for: original, now: now)!

        XCTAssertEqual(snooze.content.title, content.title)
        XCTAssertEqual(snooze.content.body, content.body)
    }

    // MARK: - Surviving a rebuild

    func testSnoozeSurvivesRebuildWhileItsServiceIsStillDue() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let oil = Service(name: "Oil Change", dueDate: dueIn(1))
        oil.vehicle = vehicle
        vehicle.services = [oil]
        let snooze = ServiceNotificationScheduler.snoozeRequest(for: delivered([oil], vehicle: vehicle), now: now)!

        let kept = ServiceNotificationScheduler.snoozeWorthyServiceIDs(for: vehicle, now: now)

        XCTAssertTrue(ServiceNotificationScheduler.isKeptSnooze(snooze, keptServiceIDs: kept))
    }

    func testOverdueServiceStillKeepsItsSnooze() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let oil = Service(name: "Oil Change", dueDate: dueIn(-5))
        oil.vehicle = vehicle
        vehicle.services = [oil]

        XCTAssertTrue(ServiceNotificationScheduler.snoozeWorthyServiceIDs(for: vehicle, now: now).contains(oil.id.uuidString))
    }

    func testCompletingTheServiceRetiresItsSnooze() {
        // Marking it done moves the due date months out.
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let oil = Service(name: "Oil Change", dueDate: dueIn(1))
        oil.vehicle = vehicle
        vehicle.services = [oil]
        let snooze = ServiceNotificationScheduler.snoozeRequest(for: delivered([oil], vehicle: vehicle), now: now)!

        oil.dueDate = dueIn(180)
        let kept = ServiceNotificationScheduler.snoozeWorthyServiceIDs(for: vehicle, now: now)

        XCTAssertFalse(ServiceNotificationScheduler.isKeptSnooze(snooze, keptServiceIDs: kept))
    }

    func testOrdinaryRemindersAreNeverKeptThroughARebuild() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let oil = Service(name: "Oil Change", dueDate: dueIn(1))
        let original = delivered([oil], vehicle: vehicle)

        XCTAssertFalse(ServiceNotificationScheduler.isKeptSnooze(original, keptServiceIDs: [oil.id.uuidString]))
    }

    // MARK: - Marbete snooze

    private func marbeteRequest(daysBeforeDue: Int, vehicleID: UUID = UUID()) -> UNNotificationRequest {
        MarbeteNotificationScheduler.buildMarbeteNotificationRequest(
            vehicleName: "My Car",
            vehicleID: vehicleID,
            notificationDate: now,
            daysBeforeDue: daysBeforeDue
        )
    }

    func testMarbeteSnoozeReplaysTheBannerUnderTheCancellableSnoozeID() {
        let vehicleID = UUID()
        let original = marbeteRequest(daysBeforeDue: 30, vehicleID: vehicleID)

        let snooze = MarbeteNotificationScheduler.snoozeRequest(for: original, now: now)!

        XCTAssertEqual(snooze.content.title, original.content.title)
        XCTAssertEqual(snooze.content.body, original.content.body)
        XCTAssertTrue(
            MarbeteNotificationScheduler.marbeteCancellationIDs(for: vehicleID).contains(snooze.identifier),
            "Renewing or deleting must still reach the snooze"
        )
        XCTAssertNotEqual(snooze.identifier, original.identifier, "The later reminders must stay scheduled")
        assertFiresTomorrowAtNine(snooze)
    }

    func testMarbeteSnoozeOfExpiresTomorrowBecomesFinalNotice() {
        let original = marbeteRequest(daysBeforeDue: 1)
        let finalNotice = marbeteRequest(daysBeforeDue: MarbeteNotificationScheduler.snoozeDaysBeforeDue)

        let snooze = MarbeteNotificationScheduler.snoozeRequest(for: original, now: now)!

        XCTAssertEqual(snooze.content.title, finalNotice.content.title)
        XCTAssertEqual(snooze.content.body, finalNotice.content.body)
    }
}
