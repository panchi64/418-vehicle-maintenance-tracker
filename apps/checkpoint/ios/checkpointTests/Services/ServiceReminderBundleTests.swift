//
//  ServiceReminderBundleTests.swift
//  checkpointTests
//
//  The regression guard for notification spam: several services coming due
//  together must produce one notification, not one apiece.
//

import XCTest
import UserNotifications
@testable import checkpoint

@MainActor
final class ServiceReminderBundleTests: XCTestCase {

    // MARK: - Helpers

    private func occurrence(
        _ name: String, daysBeforeDue: Int, daysFromNow: Int, hour: Int = 12
    ) -> ServiceReminderOccurrence {
        let day = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!
        let dated = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        return ServiceReminderOccurrence(
            serviceID: UUID(), serviceName: name,
            daysBeforeDue: daysBeforeDue, notificationDate: dated
        )
    }

    // MARK: - Grouping

    func testServicesDueTheSameDayAtTheSameLeadTimeBecomeOneBundle() {
        let occurrences = [
            occurrence("Oil Change", daysBeforeDue: 0, daysFromNow: 10),
            occurrence("Tire Rotation", daysBeforeDue: 0, daysFromNow: 10),
            occurrence("Brake Fluid", daysBeforeDue: 0, daysFromNow: 10)
        ]

        let bundles = ServiceReminderBundle.bundles(from: occurrences)

        XCTAssertEqual(bundles.count, 1, "Three services due together must not produce three notifications")
        XCTAssertEqual(bundles[0].count, 3)
        XCTAssertEqual(bundles[0].serviceNames, ["Brake Fluid", "Oil Change", "Tire Rotation"])
    }

    func testSameDayDifferentTimeOfDayStillBundles() {
        // Triggers snap to the notification hour, so two reminders that differ
        // only in time of day fire at the same moment and must share a banner.
        let occurrences = [
            occurrence("Oil Change", daysBeforeDue: 0, daysFromNow: 10, hour: 8),
            occurrence("Tire Rotation", daysBeforeDue: 0, daysFromNow: 10, hour: 21)
        ]

        let bundles = ServiceReminderBundle.bundles(from: occurrences)

        XCTAssertEqual(bundles.count, 1)
    }

    func testDifferentLeadTimesOnTheSameDayStaySeparate() {
        // "Due today" and "due in 30 days" are different messages, and the
        // banner's actions apply to the whole set — so they can't share one.
        let occurrences = [
            occurrence("Oil Change", daysBeforeDue: 0, daysFromNow: 10),
            occurrence("Tire Rotation", daysBeforeDue: 30, daysFromNow: 10)
        ]

        let bundles = ServiceReminderBundle.bundles(from: occurrences)

        XCTAssertEqual(bundles.count, 2)
        XCTAssertEqual(bundles.map(\.daysBeforeDue), [30, 0], "Longer lead time sorts first on a shared day")
    }

    func testDifferentDaysStaySeparate() {
        let occurrences = [
            occurrence("Oil Change", daysBeforeDue: 0, daysFromNow: 10),
            occurrence("Tire Rotation", daysBeforeDue: 0, daysFromNow: 11)
        ]

        let bundles = ServiceReminderBundle.bundles(from: occurrences)

        XCTAssertEqual(bundles.count, 2)
    }

    func testBundlesAreOrderedByFireDate() {
        let occurrences = [
            occurrence("Late", daysBeforeDue: 0, daysFromNow: 20),
            occurrence("Early", daysBeforeDue: 0, daysFromNow: 5),
            occurrence("Middle", daysBeforeDue: 0, daysFromNow: 12)
        ]

        let bundles = ServiceReminderBundle.bundles(from: occurrences)

        XCTAssertEqual(bundles.flatMap(\.serviceNames), ["Early", "Middle", "Late"])
    }

    func testGroupingIsStableAcrossCalls() {
        // Identifiers and content are derived from this ordering, so an
        // unstable sort would make every reschedule look like a change.
        let occurrences = [
            occurrence("Tire Rotation", daysBeforeDue: 7, daysFromNow: 3),
            occurrence("Oil Change", daysBeforeDue: 7, daysFromNow: 3),
            occurrence("Air Filter", daysBeforeDue: 7, daysFromNow: 3)
        ]

        let first = ServiceReminderBundle.bundles(from: occurrences)
        let second = ServiceReminderBundle.bundles(from: occurrences.reversed())

        XCTAssertEqual(first, second)
    }

    func testEmptyInputProducesNoBundles() {
        XCTAssertTrue(ServiceReminderBundle.bundles(from: []).isEmpty)
    }

    // MARK: - Copy

    private func bundle(_ names: [String], daysBeforeDue: Int) -> ServiceReminderBundle {
        let date = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        return ServiceReminderBundle(
            daysBeforeDue: daysBeforeDue,
            notificationDate: date,
            occurrences: names.map {
                ServiceReminderOccurrence(
                    serviceID: UUID(), serviceName: $0,
                    daysBeforeDue: daysBeforeDue, notificationDate: date
                )
            }
        )
    }

    func testSingleServiceKeepsItsOwnName() {
        let single = bundle(["Oil Change"], daysBeforeDue: 0)

        XCTAssertEqual(ServiceReminderCopy.title(for: single), "Oil Change Due Today")
        XCTAssertEqual(
            ServiceReminderCopy.body(for: single, vehicleName: "My Car"),
            "My Car - Oil Change is due for maintenance"
        )
    }

    func testBundledTitleCountsInsteadOfNaming() {
        let three = bundle(["Oil Change", "Tire Rotation", "Brake Fluid"], daysBeforeDue: 0)

        XCTAssertEqual(ServiceReminderCopy.title(for: three), "3 services due today")
    }

    func testBundledTitlePerLeadTime() {
        let names = ["Oil Change", "Tire Rotation"]
        XCTAssertEqual(ServiceReminderCopy.title(for: bundle(names, daysBeforeDue: 1)), "2 services due tomorrow")
        XCTAssertEqual(ServiceReminderCopy.title(for: bundle(names, daysBeforeDue: 7)), "2 services due in 1 week")
        XCTAssertEqual(ServiceReminderCopy.title(for: bundle(names, daysBeforeDue: 30)), "2 services coming up")
    }

    func testBundledBodyNamesEveryService() {
        let three = bundle(["Oil Change", "Tire Rotation", "Brake Fluid"], daysBeforeDue: 0)

        let body = ServiceReminderCopy.body(for: three, vehicleName: "My Car")

        XCTAssertTrue(body.hasPrefix("My Car - "), "The vehicle still leads the body")
        for name in three.serviceNames {
            XCTAssertTrue(body.contains(name), "\(name) must appear in the bundled body")
        }
    }

    func testBundledBodySummarizesBeyondTheNamedLimit() {
        let names = (1...7).map { "Service \($0)" }
        let many = bundle(names, daysBeforeDue: 0)

        let body = ServiceReminderCopy.body(for: many, vehicleName: "My Car")

        let extra = names.count - ServiceReminderCopy.maxNamedServices
        XCTAssertTrue(body.contains("and \(extra) more"), "Overflow should be counted, not truncated: \(body)")
        XCTAssertFalse(body.contains("Service 7"), "Names past the limit are summarized, not listed")
    }

    // MARK: - End to end

    func testVehicleWithThreeServicesDueTogetherSchedulesOneRequestPerLeadTime() async {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let dueDate = Calendar.current.date(byAdding: .day, value: 45, to: Date())!

        let services = ["Oil Change", "Tire Rotation", "Brake Fluid"].map {
            Service(name: $0, dueDate: dueDate)
        }
        services.forEach { $0.vehicle = vehicle }
        vehicle.services = services

        let bundles = ServiceReminderBundle.bundles(
            from: ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: nil)
        )

        // Four lead times, three services: four notifications, not twelve.
        XCTAssertEqual(bundles.count, NotificationService.defaultReminderIntervals.count)
        XCTAssertTrue(bundles.allSatisfy { $0.count == 3 })

        let dueDay = bundles.first { $0.daysBeforeDue == 0 }
        XCTAssertNotNil(dueDay)
        let request = ServiceNotificationScheduler.buildNotificationRequest(
            for: dueDay!, vehicle: vehicle
        )
        XCTAssertEqual(request.content.title, "3 services due today")
        XCTAssertEqual(
            (request.content.userInfo["serviceIDs"] as? [String])?.count, 3,
            "Every service in the bundle must be reachable from the payload"
        )
        XCTAssertNil(
            request.content.userInfo["serviceID"],
            "A multi-service bundle must not name one arbitrary member as THE service"
        )
    }

    func testReminderPlanResolvesEverythingSynchronously() {
        // Scheduling hands the notification center an already-built plan and
        // never reads the model again. An earlier version deferred the whole
        // rebuild into a Task, which read the Vehicle after the caller had
        // moved on — a SwiftData "model instance was destroyed" trap rather
        // than a nil, and it took down two unrelated test suites.
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let serviceItem = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: 45, to: Date())!
        )
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let plan = ServiceNotificationScheduler.reminderPlan(for: vehicle)

        XCTAssertEqual(plan.vehicleID, vehicle.id)
        XCTAssertEqual(plan.requests.count, NotificationService.defaultReminderIntervals.count)
        XCTAssertNotNil(
            serviceItem.notificationID,
            "The plan must record its marks up front, not once the adds land"
        )
    }
}
