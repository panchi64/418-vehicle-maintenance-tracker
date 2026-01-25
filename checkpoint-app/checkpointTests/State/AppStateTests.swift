//
//  AppStateTests.swift
//  checkpointTests
//
//  Tests for AppState, the shared state management for tab navigation
//

import XCTest
import SwiftData
@testable import checkpoint

final class AppStateTests: XCTestCase {

    // MARK: - Tab Enum Tests (No MainActor needed)

    func testTab_AllCases() {
        // Then
        XCTAssertEqual(AppState.Tab.allCases.count, 3)
        XCTAssertTrue(AppState.Tab.allCases.contains(.home))
        XCTAssertTrue(AppState.Tab.allCases.contains(.services))
        XCTAssertTrue(AppState.Tab.allCases.contains(.costs))
    }

    func testTab_Titles() {
        // Then
        XCTAssertEqual(AppState.Tab.home.title, "HOME")
        XCTAssertEqual(AppState.Tab.services.title, "SERVICES")
        XCTAssertEqual(AppState.Tab.costs.title, "COSTS")
    }

    func testTab_Icons() {
        // Then
        XCTAssertEqual(AppState.Tab.home.icon, "house.fill")
        XCTAssertEqual(AppState.Tab.services.icon, "wrench.and.screwdriver.fill")
        XCTAssertEqual(AppState.Tab.costs.icon, "dollarsign.circle.fill")
    }

    // MARK: - Initialization Tests

    @MainActor
    func testAppState_DefaultInitialization() async {
        // Given/When
        let appState = AppState()

        // Then
        XCTAssertNil(appState.selectedVehicle)
        XCTAssertEqual(appState.selectedTab, .home)
        XCTAssertFalse(appState.showVehiclePicker)
        XCTAssertFalse(appState.showAddVehicle)
        XCTAssertFalse(appState.showAddService)
        XCTAssertFalse(appState.showEditVehicle)
        XCTAssertNil(appState.selectedService)
    }

    // MARK: - Navigation Method Tests

    @MainActor
    func testNavigateToServices() async {
        // Given
        let appState = AppState()
        XCTAssertEqual(appState.selectedTab, .home)

        // When
        appState.navigateToServices()

        // Then
        XCTAssertEqual(appState.selectedTab, .services)
    }

    @MainActor
    func testNavigateToCosts() async {
        // Given
        let appState = AppState()
        XCTAssertEqual(appState.selectedTab, .home)

        // When
        appState.navigateToCosts()

        // Then
        XCTAssertEqual(appState.selectedTab, .costs)
    }

    @MainActor
    func testNavigateToHome() async {
        // Given
        let appState = AppState()
        appState.selectedTab = .costs
        XCTAssertEqual(appState.selectedTab, .costs)

        // When
        appState.navigateToHome()

        // Then
        XCTAssertEqual(appState.selectedTab, .home)
    }

    // MARK: - Sheet State Tests

    @MainActor
    func testSheetStates_CanBeToggled() async {
        // Given
        let appState = AppState()

        // When/Then - Vehicle Picker
        appState.showVehiclePicker = true
        XCTAssertTrue(appState.showVehiclePicker)
        appState.showVehiclePicker = false
        XCTAssertFalse(appState.showVehiclePicker)

        // When/Then - Add Vehicle
        appState.showAddVehicle = true
        XCTAssertTrue(appState.showAddVehicle)
        appState.showAddVehicle = false
        XCTAssertFalse(appState.showAddVehicle)

        // When/Then - Add Service
        appState.showAddService = true
        XCTAssertTrue(appState.showAddService)
        appState.showAddService = false
        XCTAssertFalse(appState.showAddService)

        // When/Then - Edit Vehicle
        appState.showEditVehicle = true
        XCTAssertTrue(appState.showEditVehicle)
        appState.showEditVehicle = false
        XCTAssertFalse(appState.showEditVehicle)
    }

    // MARK: - Vehicle Selection Tests

    @MainActor
    func testSelectedVehicle_CanBeSet() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self, ServicePreset.self,
            configurations: config
        )
        let modelContext = modelContainer.mainContext

        let appState = AppState()
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022
        )
        modelContext.insert(vehicle)

        // When
        appState.selectedVehicle = vehicle

        // Then
        XCTAssertNotNil(appState.selectedVehicle)
        XCTAssertEqual(appState.selectedVehicle?.name, "Test Car")

        // Cleanup: clear reference before test ends to avoid deallocation crash
        appState.selectedVehicle = nil
    }

    @MainActor
    func testSelectedVehicle_CanBeCleared() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self, ServicePreset.self,
            configurations: config
        )
        let modelContext = modelContainer.mainContext

        let appState = AppState()
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022
        )
        modelContext.insert(vehicle)
        appState.selectedVehicle = vehicle

        // When
        appState.selectedVehicle = nil

        // Then
        XCTAssertNil(appState.selectedVehicle)
    }

    // MARK: - Tab Selection Tests

    @MainActor
    func testSelectedTab_CanBeChanged() async {
        // Given
        let appState = AppState()

        // When/Then
        appState.selectedTab = .services
        XCTAssertEqual(appState.selectedTab, .services)

        appState.selectedTab = .costs
        XCTAssertEqual(appState.selectedTab, .costs)

        appState.selectedTab = .home
        XCTAssertEqual(appState.selectedTab, .home)
    }
}
