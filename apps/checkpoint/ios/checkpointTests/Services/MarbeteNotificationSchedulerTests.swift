//
//  MarbeteNotificationSchedulerTests.swift
//  checkpointTests
//
//  Unit tests for MarbeteNotificationScheduler
//

import XCTest
import UserNotifications
@testable import checkpoint

@MainActor
final class MarbeteNotificationSchedulerTests: XCTestCase {

    override func tearDown() {
        // Drop anything scheduled during a test so it can't bleed into others.
        NotificationService.shared.cancelAllNotifications()
        super.tearDown()
    }

    // MARK: - Identifier scheme

    func testSnoozeUsesZeroDayIdentifier() {
        let vehicleID = UUID()
        XCTAssertEqual(MarbeteNotificationScheduler.snoozeDaysBeforeDue, 0)
        let id = MarbeteNotificationScheduler.marbeteReminderID(
            for: vehicleID, daysBeforeDue: MarbeteNotificationScheduler.snoozeDaysBeforeDue
        )
        XCTAssertEqual(id, "marbete-\(vehicleID.uuidString)-0d")
    }

    // MARK: - Snooze / imminent copy (finding 1)

    func testSnoozeCopyIsNotDefaultZeroDays() {
        // The 0-day case used to fall into the default arm and render
        // "Marbete Status: 0 Days" / "expires in 0 days".
        let request = MarbeteNotificationScheduler.buildMarbeteNotificationRequest(
            vehicleName: "My Car",
            vehicleID: UUID(),
            notificationDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            daysBeforeDue: MarbeteNotificationScheduler.snoozeDaysBeforeDue
        )
        XCTAssertEqual(request.content.title, String(localized: "Marbete Status: FINAL NOTICE"))
        XCTAssertFalse(request.content.title.contains("0 Days"))
        XCTAssertFalse(request.content.body.contains("0 days"))
        XCTAssertTrue(request.content.body.contains("My Car"))
    }

    // MARK: - Cancellation reaches the snooze request (finding 1)
    //
    // The regression was cancelMarbeteNotifications sweeping only the default
    // interval IDs, stranding the snoozed 0-day request across marbete edits
    // and vehicle deletion. The unit-testable contract is the cancellation ID
    // list — the simulator test host has no notification authorization, so
    // live pending-request state can't be asserted here.

    func testCancellationListCoversSnoozedRequest() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let snoozedRequest = MarbeteNotificationScheduler.buildMarbeteNotificationRequest(
            vehicleName: vehicle.displayName,
            vehicleID: vehicle.id,
            notificationDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            daysBeforeDue: MarbeteNotificationScheduler.snoozeDaysBeforeDue
        )

        let cancelled = MarbeteNotificationScheduler.marbeteCancellationIDs(for: vehicle.id)
        XCTAssertTrue(
            cancelled.contains(snoozedRequest.identifier),
            "The exact ID snooze schedules must be in the cancellation sweep"
        )
    }

    func testCancellationListCoversAllIntervalRequests() {
        let vehicleID = UUID()
        let cancelled = MarbeteNotificationScheduler.marbeteCancellationIDs(for: vehicleID)

        for days in NotificationService.marbeteReminderIntervals {
            XCTAssertTrue(
                cancelled.contains(MarbeteNotificationScheduler.marbeteReminderID(for: vehicleID, daysBeforeDue: days)),
                "Interval \(days)d must be in the cancellation sweep"
            )
        }
    }

    // MARK: - Scheduling guards

    func testScheduleReturnsNilForExpiredMarbete() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        vehicle.marbeteExpirationMonth = 1
        vehicle.marbeteExpirationYear = Calendar.current.component(.year, from: Date()) - 2
        XCTAssertNil(MarbeteNotificationScheduler.scheduleMarbeteNotifications(for: vehicle))
    }

    func testScheduleReturnsBaseIDForFutureMarbete() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        vehicle.marbeteExpirationMonth = 12
        vehicle.marbeteExpirationYear = Calendar.current.component(.year, from: Date()) + 2
        let id = MarbeteNotificationScheduler.scheduleMarbeteNotifications(for: vehicle)
        XCTAssertEqual(id, MarbeteNotificationScheduler.marbeteBaseID(for: vehicle.id))
        XCTAssertEqual(vehicle.marbeteNotificationID, id)
    }
}
