//
//  NotificationRouteTests.swift
//  checkpointTests
//
//  Where tapping a notification, or one of its foreground buttons, takes the
//  user. The delegate stores a route; `AppState.apply` turns it into
//  navigation whenever ContentView is on screen, including after a cold launch.
//

import XCTest
import UserNotifications
@testable import checkpoint

@MainActor
final class NotificationRouteTests: XCTestCase {

    private var appState: AppState!
    private var vehicle: Vehicle!
    private var other: Vehicle!

    override func setUp() {
        super.setUp()
        appState = AppState()
        vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        other = Vehicle(name: "Other", make: "Honda", model: "Civic", year: 2020)
        appState.selectedVehicle = other
    }

    override func tearDown() {
        appState = nil
        vehicle = nil
        other = nil
        super.tearDown()
    }

    private func addServices(dueInDays days: [Int]) -> [Service] {
        let services = days.enumerated().map { index, offset in
            Service(name: "Service \(index)", dueDate: Calendar.current.date(byAdding: .day, value: offset, to: .now))
        }
        services.forEach { $0.vehicle = vehicle }
        vehicle.services = services
        return services
    }

    // MARK: - Vehicle selection

    func test_apply_selectsTheNotificationsVehicle() {
        appState.apply(.costs(vehicleID: vehicle.id), vehicles: [vehicle, other])

        XCTAssertEqual(appState.selectedVehicle?.id, vehicle.id)
        XCTAssertEqual(appState.selectedTab, .costs)
    }

    func test_apply_deletedVehicle_doesNothing() {
        appState.apply(.editVehicle(vehicleID: UUID()), vehicles: [vehicle, other])

        XCTAssertEqual(appState.selectedVehicle?.id, other.id)
        XCTAssertFalse(appState.showEditVehicle)
    }

    // MARK: - Mileage, costs, marbete

    func test_apply_updateMileage_opensMileageSheetOnHome() {
        appState.selectedTab = .costs
        appState.apply(.updateMileage(vehicleID: vehicle.id), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedTab, .home)
        XCTAssertTrue(appState.showMileageUpdate)
    }

    func test_apply_editVehicle_opensVehicleEditor() {
        appState.apply(.editVehicle(vehicleID: vehicle.id), vehicles: [vehicle])

        XCTAssertTrue(appState.showEditVehicle)
    }

    // MARK: - Service tap

    func test_apply_servicesTap_singleService_opensIt() {
        let services = addServices(dueInDays: [3])

        appState.apply(.services(vehicleID: vehicle.id, serviceIDs: [services[0].id]), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedService?.id, services[0].id)
    }

    func test_apply_servicesTap_bundle_opensServicesTab() {
        let services = addServices(dueInDays: [3, 5])

        appState.apply(.services(vehicleID: vehicle.id, serviceIDs: services.map(\.id)), vehicles: [vehicle])

        XCTAssertNil(appState.selectedService)
        XCTAssertEqual(appState.selectedTab, .services)
    }

    // MARK: - Mark as Done

    func test_apply_markDone_requestsEveryStillDueService() {
        let services = addServices(dueInDays: [0, 4])

        appState.apply(.markDone(vehicleID: vehicle.id, serviceIDs: services.map(\.id)), vehicles: [vehicle])

        XCTAssertEqual(Set(appState.markDoneRequest?.services.map(\.id) ?? []), Set(services.map(\.id)))
        XCTAssertEqual(appState.markDoneRequest?.vehicle.id, vehicle.id)
    }

    func test_apply_markDone_skipsServicesAlreadyCompleted() {
        // Completed in the app since the banner arrived: due date moved months out.
        let services = addServices(dueInDays: [0, 180])

        appState.apply(.markDone(vehicleID: vehicle.id, serviceIDs: services.map(\.id)), vehicles: [vehicle])

        XCTAssertEqual(appState.markDoneRequest?.services.map(\.id), [services[0].id])
    }

    func test_apply_markDone_allAlreadyCompleted_showsServicesInstead() {
        let services = addServices(dueInDays: [180])

        appState.apply(.markDone(vehicleID: vehicle.id, serviceIDs: services.map(\.id)), vehicles: [vehicle])

        XCTAssertNil(appState.markDoneRequest)
        XCTAssertEqual(appState.selectedTab, .services)
    }

    // MARK: - Mileage Remind Tomorrow

    func test_mileageSnooze_replaysTheBannerUnderTheVehiclesReminderID() {
        let original = MileageReminderScheduler.buildMileageReminderRequest(
            vehicleName: "My Car", vehicleID: vehicle.id, reminderDate: .now
        )

        let snooze = MileageReminderScheduler.snoozeRequest(for: original)!

        XCTAssertEqual(snooze.identifier, MileageReminderScheduler.mileageReminderID(for: vehicle.id))
        XCTAssertEqual(snooze.content.body, original.content.body)
        let trigger = snooze.trigger as? UNCalendarNotificationTrigger
        let tomorrow = Calendar.current.dateComponents([.day], from: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        XCTAssertEqual(trigger?.dateComponents.day, tomorrow.day)
    }
}
