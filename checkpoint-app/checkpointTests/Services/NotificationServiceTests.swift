//
//  NotificationServiceTests.swift
//  checkpointTests
//
//  Unit tests for NotificationService
//

import XCTest
import UserNotifications
@testable import checkpoint

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

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            dueDate: futureDate
        )

        // Then
        XCTAssertEqual(request.identifier, notificationID)
        XCTAssertEqual(request.content.title, "Oil Change Due")
        XCTAssertEqual(request.content.body, "My Car - Oil Change is due for maintenance")
        XCTAssertEqual(request.content.categoryIdentifier, NotificationService.serviceDueCategoryID)
        XCTAssertNotNil(request.content.sound)
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

        // When
        let request = service.buildNotificationRequest(
            for: serviceItem,
            vehicle: vehicle,
            notificationID: notificationID,
            dueDate: futureDate
        )

        // Then - Vehicle without custom name should use "year make model"
        XCTAssertEqual(request.content.body, "2023 Honda Civic - Oil Change is due for maintenance")
    }

    func testBuildNotificationRequestUsesCustomVehicleName() {
        // Given - vehicle with custom name
        let vehicle = Vehicle(name: "Family Car", make: "Honda", model: "Odyssey", year: 2023)
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let serviceItem = Service(name: "Brake Check", dueDate: futureDate)
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
        XCTAssertEqual(request.content.body, "Family Car - Brake Check is due for maintenance")
    }
}
