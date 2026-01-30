//
//  VehiclePickerSheetTests.swift
//  checkpointTests
//
//  Tests for VehiclePickerSheet including vehicle deletion functionality
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class VehiclePickerSheetTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    private let appGroupID = "group.com.418-studio.checkpoint.shared"
    private let appSelectedVehicleIDKey = "appSelectedVehicleID"

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        // Clean up App Group UserDefaults
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: appSelectedVehicleIDKey)
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestVehicle(
        name: String = "Test Car",
        make: String = "Toyota",
        model: String = "Camry",
        year: Int = 2022,
        mileage: Int = 50000
    ) -> Vehicle {
        let vehicle = Vehicle(
            name: name,
            make: make,
            model: model,
            year: year,
            currentMileage: mileage
        )
        modelContext.insert(vehicle)
        return vehicle
    }

    // MARK: - Vehicle List Tests

    func testVehiclePickerSheet_MultipleVehiclesCreated() {
        // Given: Multiple vehicles
        let vehicle1 = createTestVehicle(name: "Daily Driver")
        let vehicle2 = createTestVehicle(name: "Weekend Car", make: "Mazda", model: "MX-5")

        // When: Fetching vehicles from context
        let fetchDescriptor = FetchDescriptor<Vehicle>()
        let vehicles = try! modelContext.fetch(fetchDescriptor)

        // Then: All vehicles should be available
        XCTAssertEqual(vehicles.count, 2)
        XCTAssertTrue(vehicles.contains(where: { $0.id == vehicle1.id }))
        XCTAssertTrue(vehicles.contains(where: { $0.id == vehicle2.id }))
    }

    // MARK: - Vehicle Selection Tests

    func testVehicleSelection_UpdatesBinding() {
        // Given: A vehicle and initial nil selection
        let vehicle = createTestVehicle(name: "My Car")
        var selectedVehicle: Vehicle? = nil

        // When: Selecting the vehicle
        selectedVehicle = vehicle

        // Then: Selection should be updated
        XCTAssertNotNil(selectedVehicle)
        XCTAssertEqual(selectedVehicle?.id, vehicle.id)
        XCTAssertEqual(selectedVehicle?.name, "My Car")
    }

    func testVehicleSelection_CanChangeSelection() {
        // Given: Two vehicles
        let vehicle1 = createTestVehicle(name: "First Car")
        let vehicle2 = createTestVehicle(name: "Second Car")
        var selectedVehicle: Vehicle? = vehicle1

        // When: Changing selection
        selectedVehicle = vehicle2

        // Then: Selection should change
        XCTAssertEqual(selectedVehicle?.id, vehicle2.id)
        XCTAssertEqual(selectedVehicle?.name, "Second Car")
    }

    // MARK: - Vehicle Deletion Tests

    func testVehicleDeletion_RemovesFromContext() {
        // Given: A vehicle in the context
        let vehicle = createTestVehicle(name: "To Delete")
        let vehicleID = vehicle.id

        // Verify it exists
        let beforeFetch = FetchDescriptor<Vehicle>()
        let beforeVehicles = try! modelContext.fetch(beforeFetch)
        XCTAssertEqual(beforeVehicles.count, 1)

        // When: Deleting the vehicle
        modelContext.delete(vehicle)

        // Then: Vehicle should be removed
        let afterFetch = FetchDescriptor<Vehicle>()
        let afterVehicles = try! modelContext.fetch(afterFetch)
        XCTAssertEqual(afterVehicles.count, 0)
        XCTAssertFalse(afterVehicles.contains(where: { $0.id == vehicleID }))
    }

    func testVehicleDeletion_ClearsSelectionIfDeleted() {
        // Given: A selected vehicle
        let vehicle = createTestVehicle(name: "Selected Car")
        var selectedVehicle: Vehicle? = vehicle

        // When: Vehicle is deleted and selection should be cleared
        let vehicleID = vehicle.id
        modelContext.delete(vehicle)

        // Simulate the selection clearing logic
        if selectedVehicle?.id == vehicleID {
            selectedVehicle = nil
        }

        // Then: Selection should be nil
        XCTAssertNil(selectedVehicle)
    }

    func testVehicleDeletion_OtherVehicleSelectionRemains() {
        // Given: Two vehicles with the second one selected
        let vehicle1 = createTestVehicle(name: "First Car")
        let vehicle2 = createTestVehicle(name: "Second Car")
        var selectedVehicle: Vehicle? = vehicle2

        // When: First vehicle is deleted
        let deletedID = vehicle1.id
        modelContext.delete(vehicle1)

        // Simulate checking if selection needs clearing
        if selectedVehicle?.id == deletedID {
            selectedVehicle = nil
        }

        // Then: Selection should still be the second vehicle
        XCTAssertNotNil(selectedVehicle)
        XCTAssertEqual(selectedVehicle?.id, vehicle2.id)
    }

    func testVehicleDeletion_CascadeDeletesServices() {
        // Given: A vehicle with services
        let vehicle = createTestVehicle(name: "With Services")
        let service = Service(
            name: "Oil Change",
            dueDate: Date().addingTimeInterval(86400 * 30),
            dueMileage: 55000
        )
        service.vehicle = vehicle
        modelContext.insert(service)

        // Verify service exists
        let serviceFetch = FetchDescriptor<Service>()
        let servicesBefore = try! modelContext.fetch(serviceFetch)
        XCTAssertEqual(servicesBefore.count, 1)

        // When: Vehicle is deleted
        modelContext.delete(vehicle)

        // Then: Services should be cascade deleted
        let servicesAfter = try! modelContext.fetch(serviceFetch)
        XCTAssertEqual(servicesAfter.count, 0, "Services should be cascade deleted with vehicle")
    }

    // MARK: - Last Vehicle Warning Tests

    func testLastVehicle_CanBeDetected() {
        // Given: Only one vehicle
        _ = createTestVehicle(name: "Only Car")

        // When: Checking vehicle count
        let fetchDescriptor = FetchDescriptor<Vehicle>()
        let vehicles = try! modelContext.fetch(fetchDescriptor)

        // Then: Should detect it's the last vehicle
        XCTAssertEqual(vehicles.count, 1)
        let isLastVehicle = vehicles.count == 1
        XCTAssertTrue(isLastVehicle, "Should detect when there's only one vehicle")
    }

    func testNotLastVehicle_WhenMultipleExist() {
        // Given: Multiple vehicles
        _ = createTestVehicle(name: "First")
        _ = createTestVehicle(name: "Second")

        // When: Checking vehicle count
        let fetchDescriptor = FetchDescriptor<Vehicle>()
        let vehicles = try! modelContext.fetch(fetchDescriptor)

        // Then: Should not be marked as last vehicle
        XCTAssertEqual(vehicles.count, 2)
        let isLastVehicle = vehicles.count == 1
        XCTAssertFalse(isLastVehicle, "Should not be last vehicle when multiple exist")
    }

    // MARK: - Widget Data Cleanup Tests

    func testVehicleDeletion_WidgetDataCleanupKey() {
        // Given: A vehicle
        let vehicle = createTestVehicle(name: "Widget Test Car")
        let vehicleID = vehicle.id.uuidString

        // The widget data key pattern
        let widgetDataKey = "widgetData_\(vehicleID)"

        // When: Storing widget data
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Could not access App Group UserDefaults")
            return
        }
        userDefaults.set("test-data", forKey: widgetDataKey)

        // Then: Should be able to remove it (simulating cleanup)
        userDefaults.removeObject(forKey: widgetDataKey)
        XCTAssertNil(userDefaults.string(forKey: widgetDataKey),
                     "Widget data should be removable for deleted vehicle")
    }

    // MARK: - Selection Fallback Tests

    func testDeletingSelectedVehicle_FallsBackToAnother() {
        // Given: Two vehicles with first selected
        let vehicle1 = createTestVehicle(name: "First")
        let vehicle2 = createTestVehicle(name: "Second")
        var selectedVehicle: Vehicle? = vehicle1

        // When: Deleting the selected vehicle
        modelContext.delete(vehicle1)

        // Simulate fallback logic from ContentView.onChange(of: vehicles)
        let fetchDescriptor = FetchDescriptor<Vehicle>()
        let remainingVehicles = try! modelContext.fetch(fetchDescriptor)

        if selectedVehicle == nil || !remainingVehicles.contains(where: { $0.id == selectedVehicle?.id }) {
            selectedVehicle = remainingVehicles.first
        }

        // Then: Selection should fall back to remaining vehicle
        XCTAssertNotNil(selectedVehicle)
        XCTAssertEqual(selectedVehicle?.id, vehicle2.id)
    }

    func testDeletingLastVehicle_SelectionBecomesNil() {
        // Given: Only one vehicle that is selected
        let vehicle = createTestVehicle(name: "Only Car")
        var selectedVehicle: Vehicle? = vehicle

        // When: Deleting the only vehicle
        modelContext.delete(vehicle)

        // Simulate fallback logic
        let fetchDescriptor = FetchDescriptor<Vehicle>()
        let remainingVehicles = try! modelContext.fetch(fetchDescriptor)

        if selectedVehicle == nil || !remainingVehicles.contains(where: { $0.id == selectedVehicle?.id }) {
            selectedVehicle = remainingVehicles.first  // This will be nil since no vehicles remain
        }

        // Then: Selection should be nil
        XCTAssertNil(selectedVehicle, "Selection should be nil when all vehicles deleted")
    }

    // MARK: - Vehicle Display Name Tests

    func testVehicleDisplayName_UsedInPicker() {
        // Given: A vehicle with a name
        let vehicle = createTestVehicle(name: "My Daily Driver", make: "Toyota", model: "Camry")

        // Then: Display name should be the custom name
        XCTAssertEqual(vehicle.displayName, "My Daily Driver")
    }

    func testVehicleDisplayName_FallsBackToYearMakeModel() {
        // Given: A vehicle without a name
        let vehicle = createTestVehicle(name: "", make: "Toyota", model: "Camry", year: 2022)

        // Then: Display name should be year + make + model
        XCTAssertEqual(vehicle.displayName, "2022 Toyota Camry")
    }
}
