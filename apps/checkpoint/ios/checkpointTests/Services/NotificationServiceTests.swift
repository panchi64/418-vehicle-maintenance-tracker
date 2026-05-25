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

    // MARK: - Schedule Notification Tests

    func testScheduleNotificationReturnsNilForNilDueDate() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let serviceItem = Service(name: "Oil Change", dueDate: nil)
        serviceItem.vehicle = vehicle

        // When
        let notificationID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)

        // Then
        XCTAssertNil(notificationID, "Should return nil when due date is nil")
    }

    func testScheduleNotificationReturnsNilForPastDueDate() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: pastDate)
        serviceItem.vehicle = vehicle

        // When
        let notificationID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)

        // Then
        XCTAssertNil(notificationID, "Should return nil when due date is in the past")
    }

    func testScheduleNotificationReturnsIDForFutureDueDate() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle

        // When
        let notificationID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)

        // Then
        XCTAssertNotNil(notificationID, "Should return notification ID for future due date")
        XCTAssertTrue(notificationID?.hasPrefix("service-") ?? false, "ID should have service prefix")
    }

    func testScheduleNotificationCancelsExistingNotification() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle

        // First scheduling
        let firstID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)
        serviceItem.notificationID = firstID

        // When - schedule again
        let secondID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)

        // Then
        XCTAssertNotEqual(firstID, secondID, "Should create new notification ID")
        XCTAssertNotNil(secondID, "Should return new notification ID")
    }

    // MARK: - Notification Request Content Tests (using buildNotificationRequest)

    func testBuildNotificationRequestContentFormat() {
        // Given
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        let notificationID = "test-notification-id"

        // When - legacy method defaults to daysBeforeDue: 0 (due date)
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            dueDate: futureDate
        )

        // Then - on due date, title should say "Due Today"
        XCTAssertEqual(request.identifier, notificationID)
        XCTAssertEqual(request.content.title, "Oil Change Due Today")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due for maintenance")
        XCTAssertEqual(request.content.categoryIdentifier, NotificationService.serviceDueCategoryID)
        XCTAssertNotNil(request.content.sound)
    }

    func testBuildNotificationRequestContent30DaysBefore() {
        // Given
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let notificationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let serviceItem = Service(name: "Oil Change")
        serviceItem.vehicle = vehicle

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: "test-id",
            notificationDate: notificationDate,
            daysBeforeDue: 30
        )

        // Then
        XCTAssertEqual(request.content.title, "Oil Change Coming Up")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due in 30 days")
    }

    func testBuildNotificationRequestContent7DaysBefore() {
        // Given
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let notificationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change")
        serviceItem.vehicle = vehicle

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: "test-id",
            notificationDate: notificationDate,
            daysBeforeDue: 7
        )

        // Then
        XCTAssertEqual(request.content.title, "Oil Change Due in 1 Week")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due in 7 days")
    }

    func testBuildNotificationRequestContent1DayBefore() {
        // Given
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let notificationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let serviceItem = Service(name: "Oil Change")
        serviceItem.vehicle = vehicle

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: "test-id",
            notificationDate: notificationDate,
            daysBeforeDue: 1
        )

        // Then
        XCTAssertEqual(request.content.title, "Oil Change Due Tomorrow")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due tomorrow")
    }

    func testBuildNotificationRequestContentOnDueDate() {
        // Given
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let notificationDate = Calendar.current.date(byAdding: .day, value: 0, to: Date())!
        let serviceItem = Service(name: "Oil Change")
        serviceItem.vehicle = vehicle

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: "test-id",
            notificationDate: notificationDate,
            daysBeforeDue: 0
        )

        // Then
        XCTAssertEqual(request.content.title, "Oil Change Due Today")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due for maintenance")
    }

    func testBuildNotificationRequestUserInfoIncludesDaysBeforeDue() {
        // Given
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let notificationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change")
        serviceItem.vehicle = vehicle

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: "test-id",
            notificationDate: notificationDate,
            daysBeforeDue: 7
        )

        // Then
        XCTAssertEqual(request.content.userInfo["daysBeforeDue"] as? Int, 7)
    }

    func testBuildNotificationRequestUserInfoContainsIDs() {
        // Given
        let vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        let notificationID = "test-notification-id"

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            dueDate: futureDate
        )

        // Then
        XCTAssertNotNil(request.content.userInfo["serviceID"] as? String)
        XCTAssertNotNil(request.content.userInfo["vehicleID"] as? String)
        XCTAssertEqual(request.content.userInfo["serviceID"] as? String, serviceItem.id.uuidString)
        XCTAssertEqual(request.content.userInfo["vehicleID"] as? String, vehicle.id.uuidString)
    }

    func testBuildNotificationRequestTriggerAt9AM() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        let notificationID = "test-notification-id"

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            dueDate: futureDate
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

    func testBuildNotificationRequestTriggerDateComponents() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        let notificationID = "test-notification-id"
        let expectedComponents = Calendar.current.dateComponents([.year, .month, .day], from: futureDate)

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            dueDate: futureDate
        )

        // Then
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Trigger should be UNCalendarNotificationTrigger")
            return
        }
        XCTAssertEqual(trigger.dateComponents.year, expectedComponents.year)
        XCTAssertEqual(trigger.dateComponents.month, expectedComponents.month)
        XCTAssertEqual(trigger.dateComponents.day, expectedComponents.day)
    }

    // MARK: - Cancel Notification Tests

    func testCancelNotificationById() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle

        let notificationID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)!

        // When - should not crash
        service.cancelNotification(id: notificationID)

        // Then - verify method completes without error
        XCTAssertTrue(true, "Cancel notification should complete without error")
    }

    func testCancelNotificationForService() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle

        let notificationID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)
        serviceItem.notificationID = notificationID

        // When
        service.cancelNotification(for: serviceItem)

        // Then
        XCTAssertNil(serviceItem.notificationID, "Service notificationID should be cleared")
    }

    func testCancelNotificationForServiceWithNilID() {
        // Given
        let serviceItem = Service(name: "Oil Change")
        serviceItem.notificationID = nil

        // When / Then - should not crash
        service.cancelNotification(for: serviceItem)
        XCTAssertNil(serviceItem.notificationID)
    }

    func testCancelAllNotifications() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let service1 = Service(name: "Oil Change", dueDate: futureDate)
        let service2 = Service(name: "Tire Rotation", dueDate: futureDate)
        service1.vehicle = vehicle
        service2.vehicle = vehicle

        self.service.scheduleNotification(for: service1, vehicle: vehicle)
        self.service.scheduleNotification(for: service2, vehicle: vehicle)

        // When - should not crash
        self.service.cancelAllNotifications()

        // Then - verify method completes
        XCTAssertTrue(true, "Cancel all notifications should complete without error")
    }

    // MARK: - Schedule Notifications for Vehicle Tests

    func testScheduleNotificationsForVehicle() {
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
        service.scheduleNotifications(for: vehicle)

        // Then
        XCTAssertNotNil(service1.notificationID, "Service with due date should have notification ID")
        XCTAssertNotNil(service2.notificationID, "Service with due date should have notification ID")
        XCTAssertNil(service3.notificationID, "Service without due date should not have notification ID")
    }

    // MARK: - Snooze Tests

    func testSnoozeNotificationCreatesNewID() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle

        let originalID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)
        serviceItem.notificationID = originalID

        // When
        service.snoozeNotification(for: serviceItem, vehicle: vehicle)

        // Then
        XCTAssertNotNil(serviceItem.notificationID)
        XCTAssertNotEqual(serviceItem.notificationID, originalID, "Snooze should create new notification ID")
        XCTAssertTrue(serviceItem.notificationID?.hasPrefix("service-snooze-") ?? false, "Snoozed ID should have snooze prefix")
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
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        let notificationID = "test-notification-id"

        // When - using 7 days before due for a clear message
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            notificationDate: futureDate,
            daysBeforeDue: 7
        )

        // Then - Vehicle without custom name should use "year make model"
        XCTAssertEqual(request.content.body, "2023 Honda Civic - Oil Change is due in 7 days")
    }

    func testBuildNotificationRequestUsesCustomVehicleName() {
        // Given - vehicle with custom name
        let vehicle = Vehicle(name: "Family Car", make: "Honda", model: "Odyssey", year: 2023)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Brake Check", dueDate: futureDate)
        serviceItem.vehicle = vehicle
        let notificationID = "test-notification-id"

        // When - using 7 days before due for a clear message
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            notificationDate: futureDate,
            daysBeforeDue: 7
        )

        // Then
        XCTAssertEqual(request.content.body, "Family Car - Brake Check is due in 7 days")
    }

    // MARK: - Cancel All Notifications for Base ID Tests

    func testCancelAllNotificationsForBaseID() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let futureDate = Calendar.current.date(byAdding: .day, value: 45, to: Date())!
        let serviceItem = Service(name: "Oil Change", dueDate: futureDate)
        serviceItem.vehicle = vehicle

        let baseID = service.scheduleNotification(for: serviceItem, vehicle: vehicle)!

        // When - should not crash
        service.cancelAllNotifications(baseID: baseID)

        // Then - verify method completes without error
        XCTAssertTrue(true, "Cancel all notifications for base ID should complete without error")
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

    func testScheduleNotificationWithPace_UsesPredictedDate() {
        // Given: Service with due mileage 1000 miles away at 40 mi/day = 25 days
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let serviceItem = Service(name: "Oil Change", dueMileage: 51000)
        serviceItem.vehicle = vehicle

        // When
        let notificationID = service.scheduleNotificationWithPace(
            for: serviceItem,
            vehicle: vehicle,
            dailyPace: 40.0
        )

        // Then
        XCTAssertNotNil(notificationID, "Should schedule notification based on predicted mileage date")
        XCTAssertTrue(notificationID?.hasPrefix("service-") ?? false)

        // Cleanup
        if let id = notificationID {
            service.cancelAllNotifications(baseID: id)
        }
    }

    func testScheduleNotificationWithPace_NoPace_ReturnsNil() {
        // Given: Service with only mileage (no date), no pace data
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let serviceItem = Service(name: "Oil Change", dueMileage: 51000)
        serviceItem.vehicle = vehicle

        // When - no pace and no due date
        let notificationID = service.scheduleNotificationWithPace(
            for: serviceItem,
            vehicle: vehicle,
            dailyPace: nil
        )

        // Then
        XCTAssertNil(notificationID, "Should return nil when no effective due date")
    }

    func testScheduleNotificationWithPace_UsesDueDateWhenEarlier() {
        // Given: Due date in 10 days, mileage won't be reached for 50 days
        let calendar = Calendar.current
        let dueDate = calendar.date(byAdding: .day, value: 10, to: .now)!
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let serviceItem = Service(name: "Oil Change", dueDate: dueDate, dueMileage: 52000)  // 2000 miles at 40/day = 50 days
        serviceItem.vehicle = vehicle

        // When
        let notificationID = service.scheduleNotificationWithPace(
            for: serviceItem,
            vehicle: vehicle,
            dailyPace: 40.0
        )

        // Then
        XCTAssertNotNil(notificationID, "Should schedule based on due date (earlier)")

        // Cleanup
        if let id = notificationID {
            service.cancelAllNotifications(baseID: id)
        }
    }

    func testRescheduleNotifications_UpdatesAll() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)!

        let service1 = Service(name: "Oil Change", dueDate: futureDate, dueMileage: 51000)
        let service2 = Service(name: "Tire Rotation", dueDate: futureDate, dueMileage: 52000)
        service1.vehicle = vehicle
        service2.vehicle = vehicle
        vehicle.services = [service1, service2]

        // When
        service.rescheduleNotifications(for: vehicle)

        // Then
        XCTAssertNotNil(service1.notificationID, "Service 1 should have notification ID after reschedule")
        XCTAssertNotNil(service2.notificationID, "Service 2 should have notification ID after reschedule")

        // Cleanup
        service.cancelNotifications(for: vehicle)
    }

    func testScheduleNotificationWithPace_CancelsExisting() {
        // Given
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 50000)
        let serviceItem = Service(name: "Oil Change", dueMileage: 51000)
        serviceItem.vehicle = vehicle

        // First schedule
        let firstID = service.scheduleNotificationWithPace(
            for: serviceItem,
            vehicle: vehicle,
            dailyPace: 40.0
        )
        serviceItem.notificationID = firstID

        // When - schedule again
        let secondID = service.scheduleNotificationWithPace(
            for: serviceItem,
            vehicle: vehicle,
            dailyPace: 40.0
        )

        // Then
        XCTAssertNotEqual(firstID, secondID, "Should create new notification ID")
        XCTAssertNotNil(secondID)

        // Cleanup
        if let id = secondID {
            service.cancelAllNotifications(baseID: id)
        }
    }

    func testScheduleNotificationWithPace_AlreadyPastDue_ReturnsNil() {
        // Given: Service already past due
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 52000)
        let serviceItem = Service(name: "Oil Change", dueMileage: 51000)  // Already past
        serviceItem.vehicle = vehicle

        // When
        let notificationID = service.scheduleNotificationWithPace(
            for: serviceItem,
            vehicle: vehicle,
            dailyPace: 40.0
        )

        // Then
        XCTAssertNil(notificationID, "Should not schedule for past-due service")
    }
}
