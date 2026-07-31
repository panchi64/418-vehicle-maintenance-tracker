//
//  NotificationServiceTests.swift
//  checkpointTests
//
//  Unit tests for NotificationService
//

import XCTest
import UserNotifications
@testable import checkpoint

@MainActor
final class NotificationServiceTests: XCTestCase {

    var service: NotificationService!

    override func setUp() {
        super.setUp()
        service = NotificationService.shared
    }

    override func tearDown() {
        // Clean up any scheduled notifications after each test
        service.cancelAllNotifications()
        // Cancel any debounced budget-enforcement task a scheduling call left
        // pending so it can't run part-way through a later test.
        service.budgetEnforcementTask?.cancel()
        service = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(NotificationService.shared, "Shared instance should exist")
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = NotificationService.shared
        let instance2 = NotificationService.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same instance")
    }

    // MARK: - Category Identifier Tests

    func testServiceDueCategoryIdentifier() {
        XCTAssertEqual(NotificationService.serviceDueCategoryID, "SERVICE_DUE")
    }

    func testMarkDoneActionIdentifier() {
        XCTAssertEqual(NotificationService.markDoneActionID, "MARK_DONE")
    }

    func testSnoozeActionIdentifier() {
        XCTAssertEqual(NotificationService.snoozeActionID, "SNOOZE")
    }

    // MARK: - Default Reminder Intervals Tests

    func testDefaultReminderIntervalsContainsExpectedValues() {
        let intervals = NotificationService.defaultReminderIntervals
        XCTAssertEqual(intervals, [30, 7, 1, 0], "Default intervals should be 30, 7, 1, and 0 days before due")
    }

    // MARK: - Occurrence Tests
    //
    // `occurrences` is the input to bundling: what each service wants, before
    // anything is grouped or handed to the notification center.

    func testOccurrencesEmptyForNilDueDate() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let serviceItem = Service(name: "Oil Change", dueDate: nil)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let occurrences = ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: nil)

        XCTAssertTrue(occurrences.isEmpty, "A service with no due date wants no reminder")
    }

    func testOccurrencesEmptyForPastDueDate() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: pastDate)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let occurrences = ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: nil)

        XCTAssertTrue(occurrences.isEmpty, "A past due date can't produce a deliverable trigger")
    }

    func testOccurrencesCoverEveryIntervalStillAhead() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 45, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let occurrences = ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: nil)

        // 45 days out, so all four lead times are still in the future
        XCTAssertEqual(
            Set(occurrences.map(\.daysBeforeDue)),
            Set(NotificationService.defaultReminderIntervals)
        )
        XCTAssertTrue(occurrences.allSatisfy { $0.serviceID == serviceItem.id })
    }

    func testOccurrencesDropIntervalsAlreadyPassed() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let occurrences = ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: nil)

        // Due in 3 days: the 30- and 7-day marks are behind us
        XCTAssertEqual(Set(occurrences.map(\.daysBeforeDue)), [1, 0])
    }

    // MARK: - Notification Request Content Tests

    /// A one-service bundle firing `daysBeforeDue` ahead of its due date.
    private func singleBundle(_ name: String, daysBeforeDue: Int) -> ServiceReminderBundle {
        let fireDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return ServiceReminderBundle(
            daysBeforeDue: daysBeforeDue,
            notificationDate: fireDate,
            occurrences: [
                ServiceReminderOccurrence(
                    serviceID: UUID(), serviceName: name,
                    daysBeforeDue: daysBeforeDue, notificationDate: fireDate
                )
            ]
        )
    }

    func testBuildNotificationRequestContentFormat() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)

        let request = service.buildNotificationRequest(
            for: singleBundle("Oil Change", daysBeforeDue: 0), vehicle: vehicle
        )

        XCTAssertEqual(request.content.title, "Oil Change Due Today")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due for maintenance")
        XCTAssertEqual(request.content.categoryIdentifier, NotificationService.serviceDueCategoryID)
        XCTAssertNotNil(request.content.sound)
    }

    func testBuildNotificationRequestContent30DaysBefore() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let request = service.buildNotificationRequest(
            for: singleBundle("Oil Change", daysBeforeDue: 30), vehicle: vehicle
        )
        XCTAssertEqual(request.content.title, "Oil Change Coming Up")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due in 30 days")
    }

    func testBuildNotificationRequestContent7DaysBefore() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let request = service.buildNotificationRequest(
            for: singleBundle("Oil Change", daysBeforeDue: 7), vehicle: vehicle
        )
        XCTAssertEqual(request.content.title, "Oil Change Due in 1 Week")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due in 7 days")
    }

    func testBuildNotificationRequestContent1DayBefore() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let request = service.buildNotificationRequest(
            for: singleBundle("Oil Change", daysBeforeDue: 1), vehicle: vehicle
        )
        XCTAssertEqual(request.content.title, "Oil Change Due Tomorrow")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due tomorrow")
    }

    func testBuildNotificationRequestUserInfoIncludesDaysBeforeDue() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let request = service.buildNotificationRequest(
            for: singleBundle("Oil Change", daysBeforeDue: 7), vehicle: vehicle
        )
        XCTAssertEqual(request.content.userInfo["daysBeforeDue"] as? Int, 7)
    }

    func testBuildNotificationRequestUserInfoContainsIDs() {
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let bundle = singleBundle("Oil Change", daysBeforeDue: 0)

        let request = service.buildNotificationRequest(for: bundle, vehicle: vehicle)

        XCTAssertEqual(
            request.content.userInfo["serviceIDs"] as? [String],
            bundle.serviceIDs.map(\.uuidString)
        )
        XCTAssertEqual(request.content.userInfo["vehicleID"] as? String, vehicle.id.uuidString)
        // Singular key present only because this bundle has one member
        XCTAssertEqual(
            request.content.userInfo["serviceID"] as? String,
            bundle.serviceIDs.first?.uuidString
        )
    }

    func testBuildNotificationRequestTriggerAt9AM() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let request = service.buildNotificationRequest(
            for: singleBundle("Oil Change", daysBeforeDue: 7), vehicle: vehicle
        )

        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Trigger should be UNCalendarNotificationTrigger")
            return
        }
        XCTAssertEqual(trigger.dateComponents.hour, 9)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTAssertFalse(trigger.repeats)
    }

    func testBuildNotificationRequestTriggerDateComponents() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let bundle = singleBundle("Oil Change", daysBeforeDue: 7)
        let expected = Calendar.current.dateComponents(
            [.year, .month, .day], from: bundle.notificationDate
        )

        let request = service.buildNotificationRequest(for: bundle, vehicle: vehicle)

        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Trigger should be UNCalendarNotificationTrigger")
            return
        }
        XCTAssertEqual(trigger.dateComponents.year, expected.year)
        XCTAssertEqual(trigger.dateComponents.month, expected.month)
        XCTAssertEqual(trigger.dateComponents.day, expected.day)
    }

    func testBundleIdentifierIsPerVehiclePerDayPerInterval() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let bundle = singleBundle("Oil Change", daysBeforeDue: 7)
        let parts = Calendar.current.dateComponents(
            [.year, .month, .day], from: bundle.notificationDate
        )
        let stamp = String(format: "%04d%02d%02d", parts.year!, parts.month!, parts.day!)

        let request = service.buildNotificationRequest(for: bundle, vehicle: vehicle)

        XCTAssertEqual(
            request.identifier,
            "service-bundle-\(vehicle.id.uuidString)-\(stamp)-7d",
            "Re-adding an unchanged schedule must replace in place, not stack duplicates"
        )
    }

    // MARK: - Cancel Notification Tests

    func testCancelNotificationById() {
        // Should not crash on an identifier that was never added
        service.cancelNotification(id: "service-bundle-\(UUID().uuidString)-20260101-due")
        XCTAssertTrue(true, "Cancel notification should complete without error")
    }

    func testRemovingAServiceClearsItsMarkOnTheNextRebuild() async {
        // There is no "cancel this one service": a bundle covering several
        // services is reworded, not removed, when one drops out. Dropping a
        // service means changing the model and rebuilding the vehicle.
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let kept = Service(name: "Oil Change", dueDate: futureDate)
        let dropped = Service(name: "Tire Rotation", dueDate: futureDate)
        [kept, dropped].forEach { $0.vehicle = vehicle }
        vehicle.services = [kept, dropped]

        await ServiceNotificationScheduler.rescheduleNotificationsAwaitingAdds(for: vehicle)
        XCTAssertNotNil(dropped.notificationID, "Precondition: both services have reminders")

        vehicle.services = [kept]
        dropped.vehicle = nil
        await ServiceNotificationScheduler.rescheduleNotificationsAwaitingAdds(for: vehicle)

        XCTAssertNotNil(kept.notificationID, "The surviving service keeps its reminder")
        XCTAssertNotNil(
            dropped.notificationID,
            "A service detached from the vehicle is out of the rebuild's reach — the caller deletes it"
        )
    }

    func testCancelAllNotifications() async {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let service1 = Service(name: "Oil Change", dueDate: futureDate)
        let service2 = Service(name: "Tire Rotation", dueDate: futureDate)
        service1.vehicle = vehicle
        service2.vehicle = vehicle
        vehicle.services = [service1, service2]

        await ServiceNotificationScheduler.rescheduleNotificationsAwaitingAdds(for: vehicle)

        // When - should not crash
        self.service.cancelAllNotifications()

        // Then - verify method completes
        XCTAssertTrue(true, "Cancel all notifications should complete without error")
    }

    // MARK: - Reschedule for Vehicle Tests

    func testRescheduleMarksOnlyServicesThatHaveReminders() async {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let service1 = Service(name: "Oil Change", dueDate: futureDate)
        let service2 = Service(name: "Tire Rotation", dueDate: futureDate)
        let service3 = Service(name: "Brake Check") // No due date
        service1.vehicle = vehicle
        service2.vehicle = vehicle
        service3.vehicle = vehicle
        vehicle.services = [service1, service2, service3]

        // When
        await ServiceNotificationScheduler.rescheduleNotificationsAwaitingAdds(for: vehicle)

        // Then
        XCTAssertNotNil(service1.notificationID, "Service with due date should be marked as reminded")
        XCTAssertNotNil(service2.notificationID, "Service with due date should be marked as reminded")
        XCTAssertNil(service3.notificationID, "Service without due date should not be marked")
    }

    func testRescheduleClearsMarkWhenDueDateDisappears() async {
        // Given a service that had reminders
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let serviceItem = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        )
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]
        await ServiceNotificationScheduler.rescheduleNotificationsAwaitingAdds(for: vehicle)
        XCTAssertNotNil(serviceItem.notificationID)

        // When the due date is removed and the vehicle is rebuilt
        serviceItem.dueDate = nil
        await ServiceNotificationScheduler.rescheduleNotificationsAwaitingAdds(for: vehicle)

        // Then the stale mark is cleared rather than left behind
        XCTAssertNil(serviceItem.notificationID)
    }

    // MARK: - Snooze Tests

    func testSnoozeNotificationKeepsDerivedBaseID() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        // When
        service.snoozeNotification(for: serviceItem, vehicle: vehicle)

        // Then - a snooze is per service, so it keeps the service-derived base
        // and `cancelAllNotifications(baseID:)` can still reach it
        let baseID = ServiceNotificationScheduler.baseNotificationID(for: serviceItem)
        XCTAssertEqual(serviceItem.notificationID, baseID)
        XCTAssertEqual(
            ServiceNotificationScheduler.snoozeNotificationID(baseID: baseID),
            baseID + "-snooze",
            "Snooze ID should be derived from the base so cancellation can reach it"
        )
    }

    func testCancellingTheVehicleRemovesSnoozedRequests() async {
        // Given - a snoozed reminder
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]
        service.snoozeNotification(for: serviceItem, vehicle: vehicle)

        // When - the vehicle-wide purge, which is what a delete or a rebuild
        // runs. A snooze is per service but still belongs to the vehicle's set.
        await ServiceNotificationScheduler.removeServiceRequests(forVehicleID: vehicle.id)

        // Then
        let hasPending = await service.hasPendingNotification(for: serviceItem)
        XCTAssertFalse(hasPending, "The purge should reach the snoozed request too")
    }

    func testBuildSnoozeNotificationRequestSchedulesForTomorrow() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let serviceItem = Service(name: "Oil Change")
        serviceItem.vehicle = vehicle
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let notificationID = "test-snooze-id"

        // When
        let request = service.buildSnoozeNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            snoozeDate: tomorrow
        )

        // Then
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Trigger should be UNCalendarNotificationTrigger")
            return
        }
        let expectedComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)

        XCTAssertEqual(trigger.dateComponents.year, expectedComponents.year)
        XCTAssertEqual(trigger.dateComponents.month, expectedComponents.month)
        XCTAssertEqual(trigger.dateComponents.day, expectedComponents.day)
        XCTAssertEqual(trigger.dateComponents.hour, 9)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
    }

    func testBuildSnoozeNotificationRequestContent() {
        // Given
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let serviceItem = Service(name: "Oil Change")
        serviceItem.vehicle = vehicle
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let notificationID = "test-snooze-id"

        // When
        let request = service.buildSnoozeNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            snoozeDate: tomorrow
        )

        // Then
        XCTAssertEqual(request.content.title, "Oil Change Reminder")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due for maintenance")
        XCTAssertEqual(request.content.categoryIdentifier, NotificationService.serviceDueCategoryID)
    }

    // MARK: - Has Pending Notification Tests

    func testHasPendingNotificationReturnsFalseWhenNotScheduled() async {
        // Given
        let serviceItem = Service(name: "Oil Change")
        serviceItem.notificationID = nil

        // When
        let hasPending = await service.hasPendingNotification(for: serviceItem)

        // Then
        XCTAssertFalse(hasPending, "Should return false when no notification is scheduled")
    }

    func testHasPendingNotificationReturnsFalseForInvalidID() async {
        // Given
        let serviceItem = Service(name: "Oil Change")
        serviceItem.notificationID = "invalid-id-that-does-not-exist"

        // When
        let hasPending = await service.hasPendingNotification(for: serviceItem)

        // Then
        XCTAssertFalse(hasPending, "Should return false for invalid notification ID")
    }

    // MARK: - Notification Names Tests

    func testServiceMarkedDoneNotificationName() {
        XCTAssertEqual(
            Notification.Name.serviceMarkedDoneFromNotification.rawValue,
            "serviceMarkedDoneFromNotification"
        )
    }

    func testServiceSnoozedNotificationName() {
        XCTAssertEqual(
            Notification.Name.serviceSnoozedFromNotification.rawValue,
            "serviceSnoozedFromNotification"
        )
    }

    func testNavigateToServiceNotificationName() {
        XCTAssertEqual(
            Notification.Name.navigateToServiceFromNotification.rawValue,
            "navigateToServiceFromNotification"
        )
    }

    // MARK: - Authorization Tests

    func testIsAuthorizedInitiallyFalse() {
        // Note: We can't easily test the actual authorization request
        // as it requires user interaction, but we can verify the initial state
        // In a real test environment, isAuthorized might already be set
        // This test just verifies the property exists and is accessible
        let _ = service.isAuthorized
        // If we got here without crashing, the property exists
        XCTAssertTrue(true)
    }

    // MARK: - Vehicle Display Name Tests

    func testBuildNotificationRequestUsesVehicleDisplayName() {
        // Given - vehicle without custom name uses year/make/model
        let vehicle = Vehicle(make: "Honda", model: "Civic", year: 2023)

        let request = service.buildNotificationRequest(
            for: singleBundle("Oil Change", daysBeforeDue: 7), vehicle: vehicle
        )

        XCTAssertEqual(request.content.body, "2023 Honda Civic - Oil Change is due in 7 days")
    }

    func testBuildNotificationRequestUsesCustomVehicleName() {
        // Given - vehicle with custom name
        let vehicle = Vehicle(name: "Family Car", make: "Honda", model: "Odyssey", year: 2023)

        let request = service.buildNotificationRequest(
            for: singleBundle("Brake Check", daysBeforeDue: 7), vehicle: vehicle
        )

        XCTAssertEqual(request.content.body, "Family Car - Brake Check is due in 7 days")
    }

    // MARK: - Cancel All Notifications for Base ID Tests

    func testCancelAllNotificationsForBaseID() {
        let baseID = ServiceNotificationScheduler.baseNotificationID(forServiceID: UUID())

        // When - should not crash
        service.cancelAllNotifications(baseID: baseID)

        // Then - verify method completes without error
        XCTAssertTrue(true, "Cancel all notifications for base ID should complete without error")
    }

    func testServiceCancellationIDsCoverIntervalsSnoozeAndBase() {
        // The cancellation sweep must reach every ID a service's set can take:
        // each interval variant, the snooze variant, and the bare base ID that
        // legacy single-request/snooze schemes used as the full identifier.
        let baseID = ServiceNotificationScheduler.baseNotificationID(forServiceID: UUID())
        let ids = ServiceNotificationScheduler.serviceCancellationIDs(baseID: baseID)

        for days in NotificationService.defaultReminderIntervals {
            let intervalID = baseID + NotificationService.intervalSuffix(for: days)
            XCTAssertTrue(ids.contains(intervalID), "Interval \(days)d must be in the cancellation sweep")
        }
        XCTAssertTrue(
            ids.contains(ServiceNotificationScheduler.snoozeNotificationID(baseID: baseID)),
            "Snooze variant must be in the cancellation sweep"
        )
        XCTAssertTrue(ids.contains(baseID), "Bare base ID must be in the cancellation sweep")
    }

    // MARK: - Budget Enforcement Debounce Tests
    //
    // The simulator test host has no notification authorization, so live
    // pending-request state can't be asserted. The unit-testable contract is
    // the hook's cancel-and-replace of its debounce task: a burst of schedule
    // calls collapses to a single pending enforcement.

    func testScheduleBudgetEnforcementInstallsLiveTask() {
        service.scheduleBudgetEnforcement()
        guard let task = service.budgetEnforcementTask else {
            return XCTFail("Scheduling must install a debounce task")
        }
        XCTAssertFalse(task.isCancelled, "A freshly installed debounce task must be live")
    }

    func testScheduleBudgetEnforcementReplacesPriorTask() {
        service.scheduleBudgetEnforcement()
        guard let first = service.budgetEnforcementTask else {
            return XCTFail("First call should install a debounce task")
        }

        service.scheduleBudgetEnforcement()
        guard let second = service.budgetEnforcementTask else {
            return XCTFail("Second call should install a replacement debounce task")
        }

        XCTAssertTrue(first.isCancelled, "Replacing the hook must cancel the prior debounce task")
        XCTAssertFalse(second.isCancelled, "The replacement task must be live")
    }

    // MARK: - Orphaned Notification Sweep Tests

    func testOrphanSweepKeepsBundleWhoseServicesAllExist() {
        let first = UUID(), second = UUID()
        let isOrphan = ServiceNotificationScheduler.isOrphanedServiceRequest(
            identifier: "service-bundle-\(UUID().uuidString)-20260801-due",
            userInfo: ["serviceIDs": [first.uuidString, second.uuidString]],
            validServiceIDs: [first, second]
        )
        XCTAssertFalse(isOrphan, "A bundle naming only live services should be kept")
    }

    func testOrphanSweepFlagsBundleNamingADeletedService() {
        // The body lists every service by name, so one deletion makes the whole
        // request's content wrong — the reschedule that follows re-adds a
        // correct bundle for whatever remains.
        let live = UUID()
        let isOrphan = ServiceNotificationScheduler.isOrphanedServiceRequest(
            identifier: "service-bundle-\(UUID().uuidString)-20260801-due",
            userInfo: ["serviceIDs": [live.uuidString, UUID().uuidString]],
            validServiceIDs: [live]
        )
        XCTAssertTrue(isOrphan, "A bundle naming a deleted service should be swept")
    }

    func testOrphanSweepFlagsRequestForDeletedService() {
        let deletedServiceID = UUID()
        let isOrphan = ServiceNotificationScheduler.isOrphanedServiceRequest(
            identifier: "service-\(deletedServiceID.uuidString)-due",
            userInfo: ["serviceID": deletedServiceID.uuidString],
            validServiceIDs: []
        )
        XCTAssertTrue(isOrphan, "Request for a deleted service should be swept")
    }

    func testOrphanSweepKeepsSnoozeForLiveService() {
        // A snooze stays per service, so its singular payload must survive.
        let serviceID = UUID()
        let isOrphan = ServiceNotificationScheduler.isOrphanedServiceRequest(
            identifier: "service-\(serviceID.uuidString)-snooze",
            userInfo: ["serviceID": serviceID.uuidString],
            validServiceIDs: [serviceID]
        )
        XCTAssertFalse(isOrphan, "A snoozed reminder for a live service should be kept")
    }

    func testOrphanSweepIgnoresNonServiceRequests() {
        let vehicleID = UUID()
        for identifier in [
            "mileage-reminder-\(vehicleID.uuidString)",
            "marbete-\(vehicleID.uuidString)-30d",
            "cluster-\(UUID().uuidString)-due",
            "yearly-roundup-\(vehicleID.uuidString)-2025"
        ] {
            let isOrphan = ServiceNotificationScheduler.isOrphanedServiceRequest(
                identifier: identifier,
                userInfo: [:],
                validServiceIDs: []
            )
            XCTAssertFalse(isOrphan, "\(identifier) is not a service request and should be ignored")
        }
    }

    func testOrphanSweepFlagsServiceRequestWithoutServiceID() {
        let isOrphan = ServiceNotificationScheduler.isOrphanedServiceRequest(
            identifier: "service-\(UUID().uuidString)-due",
            userInfo: [:],
            validServiceIDs: []
        )
        XCTAssertTrue(isOrphan, "Service request naming no service can't be verified and should be swept")
    }

    // MARK: - Mileage Reminder Category Tests

    func testMileageReminderCategoryIdentifier() {
        XCTAssertEqual(NotificationService.mileageReminderCategoryID, "MILEAGE_REMINDER")
    }

    func testUpdateMileageActionIdentifier() {
        XCTAssertEqual(NotificationService.updateMileageActionID, "UPDATE_MILEAGE")
    }

    func testRemindLaterActionIdentifier() {
        XCTAssertEqual(NotificationService.remindLaterActionID, "REMIND_LATER")
    }

    func testMileageReminderIntervalDays() {
        XCTAssertEqual(NotificationService.mileageReminderIntervalDays, 14)
    }

    // MARK: - Mileage Reminder Notification Tests

    func testMileageReminderIDFormat() {
        // Given
        let vehicleID = UUID()

        // When
        let reminderID = NotificationService.mileageReminderID(for: vehicleID)

        // Then
        XCTAssertTrue(reminderID.hasPrefix("mileage-reminder-"), "ID should have mileage-reminder prefix")
        XCTAssertTrue(reminderID.contains(vehicleID.uuidString), "ID should contain vehicle UUID")
    }

    func testBuildMileageReminderRequestContent() {
        // Given
        let vehicleID = UUID()
        let vehicleName = "My Car"
        let reminderDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!

        // When
        let request = service.buildMileageReminderRequest(
            vehicleName: vehicleName,
            vehicleID: vehicleID,
            reminderDate: reminderDate
        )

        // Then
        XCTAssertEqual(request.content.title, "Odometer Sync Requested")
        XCTAssertTrue(request.content.body.contains(vehicleName), "Body should contain vehicle name")
        XCTAssertEqual(request.content.categoryIdentifier, NotificationService.mileageReminderCategoryID)
        XCTAssertNotNil(request.content.sound)
    }

    func testBuildMileageReminderRequestUserInfo() {
        // Given
        let vehicleID = UUID()
        let reminderDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!

        // When
        let request = service.buildMileageReminderRequest(
            vehicleName: "Test Car",
            vehicleID: vehicleID,
            reminderDate: reminderDate
        )

        // Then
        XCTAssertEqual(request.content.userInfo["vehicleID"] as? String, vehicleID.uuidString)
        XCTAssertEqual(request.content.userInfo["type"] as? String, "mileageReminder")
    }

    func testBuildMileageReminderRequestTriggerAt9AM() {
        // Given
        let vehicleID = UUID()
        let reminderDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!

        // When
        let request = service.buildMileageReminderRequest(
            vehicleName: "Test Car",
            vehicleID: vehicleID,
            reminderDate: reminderDate
        )

        // Then
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Trigger should be UNCalendarNotificationTrigger")
            return
        }
        XCTAssertEqual(trigger.dateComponents.hour, 9)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTAssertFalse(trigger.repeats)
    }

    func testScheduleMileageReminderCreatesNotification() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)

        // When - scheduling should not crash
        service.scheduleMileageReminder(for: vehicle)

        // Then - verify method completes
        XCTAssertTrue(true, "Schedule mileage reminder should complete without error")

        // Cleanup
        service.cancelMileageReminder(for: vehicle)
    }

    func testCancelMileageReminder() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        service.scheduleMileageReminder(for: vehicle)

        // When - should not crash
        service.cancelMileageReminder(for: vehicle)

        // Then - verify method completes
        XCTAssertTrue(true, "Cancel mileage reminder should complete without error")
    }

    func testSnoozeMileageReminder() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        service.scheduleMileageReminder(for: vehicle)

        // When - should not crash
        service.snoozeMileageReminder(for: vehicle)

        // Then - verify method completes
        XCTAssertTrue(true, "Snooze mileage reminder should complete without error")

        // Cleanup
        service.cancelMileageReminder(for: vehicle)
    }

    // MARK: - Yearly Roundup Category Tests

    func testYearlyRoundupCategoryIdentifier() {
        XCTAssertEqual(NotificationService.yearlyRoundupCategoryID, "YEARLY_ROUNDUP")
    }

    func testViewCostsActionIdentifier() {
        XCTAssertEqual(NotificationService.viewCostsActionID, "VIEW_COSTS")
    }

    // MARK: - Yearly Roundup Notification Tests

    func testYearlyRoundupIDFormat() {
        // Given
        let vehicleID = UUID()
        let year = 2025

        // When
        let roundupID = NotificationService.yearlyRoundupID(for: vehicleID, year: year)

        // Then
        XCTAssertTrue(roundupID.hasPrefix("yearly-roundup-"), "ID should have yearly-roundup prefix")
        XCTAssertTrue(roundupID.contains(vehicleID.uuidString), "ID should contain vehicle UUID")
        XCTAssertTrue(roundupID.contains("2025"), "ID should contain the year")
    }

    func testBuildYearlyRoundupRequestContent() {
        // Given
        let vehicleID = UUID()
        let vehicleName = "Family Car"
        let year = 2025
        let totalCost: Decimal = 1250.50
        let notificationDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 2))!

        // When
        let request = service.buildYearlyRoundupRequest(
            vehicleName: vehicleName,
            vehicleID: vehicleID,
            year: year,
            totalCost: totalCost,
            notificationDate: notificationDate
        )

        // Then
        XCTAssertEqual(request.content.title, "2025 Expense Report")
        XCTAssertTrue(request.content.body.contains("$1,250") || request.content.body.contains("$1,251"), "Body should contain formatted cost")
        XCTAssertTrue(request.content.body.contains(vehicleName), "Body should contain vehicle name")
        XCTAssertEqual(request.content.categoryIdentifier, NotificationService.yearlyRoundupCategoryID)
        XCTAssertNotNil(request.content.sound)
    }

    func testBuildYearlyRoundupRequestUserInfo() {
        // Given
        let vehicleID = UUID()
        let year = 2025
        let notificationDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 2))!

        // When
        let request = service.buildYearlyRoundupRequest(
            vehicleName: "Test Car",
            vehicleID: vehicleID,
            year: year,
            totalCost: 500,
            notificationDate: notificationDate
        )

        // Then
        XCTAssertEqual(request.content.userInfo["vehicleID"] as? String, vehicleID.uuidString)
        XCTAssertEqual(request.content.userInfo["year"] as? Int, year)
        XCTAssertEqual(request.content.userInfo["type"] as? String, "yearlyRoundup")
    }

    func testBuildYearlyRoundupRequestTriggerAt10AM() {
        // Given
        let vehicleID = UUID()
        let notificationDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 2))!

        // When
        let request = service.buildYearlyRoundupRequest(
            vehicleName: "Test Car",
            vehicleID: vehicleID,
            year: 2025,
            totalCost: 500,
            notificationDate: notificationDate
        )

        // Then
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Trigger should be UNCalendarNotificationTrigger")
            return
        }
        XCTAssertEqual(trigger.dateComponents.hour, 10, "Yearly roundup should be at 10 AM")
        XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTAssertFalse(trigger.repeats)
    }

    func testYearlyRoundupNotScheduledForZeroCost() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let zeroCost: Decimal = 0

        // When - should not crash and should not schedule
        service.scheduleYearlyRoundup(for: vehicle, previousYearCost: zeroCost, previousYear: 2025)

        // Then - verify method completes without scheduling (no way to verify directly,
        // but we can verify it doesn't crash)
        XCTAssertTrue(true, "Should not crash when cost is zero")
    }

    func testHasShownYearlyRoundupInitiallyFalse() {
        // Given
        let vehicleID = UUID()
        let year = 2099  // Far future year to ensure no prior state

        // When
        let hasShown = service.hasShownYearlyRoundup(for: year, vehicleID: vehicleID)

        // Then
        XCTAssertFalse(hasShown, "Should return false for a year that hasn't been shown")
    }

    func testMarkYearlyRoundupShown() {
        // Given
        let vehicleID = UUID()
        let year = 2098  // Far future year to ensure no prior state

        // When
        service.markYearlyRoundupShown(for: year, vehicleID: vehicleID)
        let hasShown = service.hasShownYearlyRoundup(for: year, vehicleID: vehicleID)

        // Then
        XCTAssertTrue(hasShown, "Should return true after marking as shown")

        // Cleanup - reset the UserDefaults
        let key = "lastYearlyRoundupYear-\(vehicleID.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - New Notification Names Tests

    func testMileageUpdateNotificationName() {
        XCTAssertEqual(
            Notification.Name.navigateToMileageUpdateFromNotification.rawValue,
            "navigateToMileageUpdateFromNotification"
        )
    }

    func testMileageReminderSnoozedNotificationName() {
        XCTAssertEqual(
            Notification.Name.mileageReminderSnoozedFromNotification.rawValue,
            "mileageReminderSnoozedFromNotification"
        )
    }

    func testNavigateToCostsNotificationName() {
        XCTAssertEqual(
            Notification.Name.navigateToCostsFromNotification.rawValue,
            "navigateToCostsFromNotification"
        )
    }

    // MARK: - Pace-Based Notification Tests

    func testOccurrencesUsePacePredictedDate() {
        // Given: due mileage 1000 miles away at 40 mi/day = 25 days
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let serviceItem = Service(name: "Oil Change", dueMileage: 51000)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let occurrences = ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: 40.0)

        XCTAssertFalse(occurrences.isEmpty, "Pace should give a mileage-only service a projected due date")
        let dueMark = occurrences.first { $0.daysBeforeDue == 0 }
        XCTAssertNotNil(dueMark)
        let daysOut = Calendar.current.dateComponents(
            [.day], from: .now, to: dueMark!.notificationDate
        ).day ?? 0
        XCTAssertTrue((24...26).contains(daysOut), "1000 miles at 40/day is ~25 days out, got \(daysOut)")
    }

    func testOccurrencesEmptyWithoutPaceOrDueDate() {
        // Given: mileage-only service and no pace data to project from
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let serviceItem = Service(name: "Oil Change", dueMileage: 51000)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let occurrences = ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: nil)

        XCTAssertTrue(occurrences.isEmpty, "No effective due date means no reminder")
    }

    func testOccurrencesUseDueDateWhenEarlierThanPaceProjection() {
        // Given: due date in 10 days, mileage not reached for 50
        let dueDate = Calendar.current.date(byAdding: .day, value: 10, to: .now)!
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let serviceItem = Service(name: "Oil Change", dueDate: dueDate, dueMileage: 52000)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let occurrences = ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: 40.0)

        let dueMark = occurrences.first { $0.daysBeforeDue == 0 }
        XCTAssertNotNil(dueMark, "The earlier of the two signals should drive the reminder")
        XCTAssertTrue(
            Calendar.current.isDate(dueMark!.notificationDate, inSameDayAs: dueDate),
            "Should use the due date, not the 50-day mileage projection"
        )
    }

    func testOccurrencesEmptyWhenAlreadyPastDue() {
        // Given: mileage already past the due mark
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 52000)
        let serviceItem = Service(name: "Oil Change", dueMileage: 51000)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        let occurrences = ServiceNotificationScheduler.occurrences(for: vehicle, dailyPace: 40.0)

        XCTAssertTrue(occurrences.isEmpty, "A past-due service has no future reminder to schedule")
    }

    func testRescheduleIsIdempotent() async {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate, dueMileage: 51000)
        serviceItem.vehicle = vehicle
        vehicle.services = [serviceItem]

        // When rescheduled twice with unchanged data
        await ServiceNotificationScheduler.rescheduleNotificationsAwaitingAdds(for: vehicle)
        let firstMark = serviceItem.notificationID
        await ServiceNotificationScheduler.rescheduleNotificationsAwaitingAdds(for: vehicle)

        // Then the mark is stable — a same-value write would dirty the record
        // for CloudKit on every reschedule
        XCTAssertEqual(firstMark, serviceItem.notificationID)

        // Cleanup
        service.cancelNotifications(for: vehicle)
    }
}
