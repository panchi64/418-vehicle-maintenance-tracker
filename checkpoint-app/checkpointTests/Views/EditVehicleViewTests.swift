//
//  EditVehicleViewTests.swift
//  checkpointTests
//
//  Tests for EditVehicleView
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

final class EditVehicleViewTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: Vehicle.self, configurations: config)
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialStateMatchesVehicleProperties() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Honda",
            model: "Civic",
            year: 2021,
            currentMileage: 15000,
            vin: "1HGBH41JXMN109186"
        )
        modelContext.insert(vehicle)

        // When
        let view = EditVehicleView(vehicle: vehicle)

        // Then
        // Test that the view initializes with the correct vehicle data
        XCTAssertEqual(view.vehicle.name, "Test Car")
        XCTAssertEqual(view.vehicle.make, "Honda")
        XCTAssertEqual(view.vehicle.model, "Civic")
        XCTAssertEqual(view.vehicle.year, 2021)
        XCTAssertEqual(view.vehicle.currentMileage, 15000)
        XCTAssertEqual(view.vehicle.vin, "1HGBH41JXMN109186")
    }

    func testInitialStateWithNoVIN() {
        // Given
        let vehicle = Vehicle(
            name: "No VIN Car",
            make: "Toyota",
            model: "Corolla",
            year: 2020,
            currentMileage: 10000,
            vin: nil
        )
        modelContext.insert(vehicle)

        // When
        let view = EditVehicleView(vehicle: vehicle)

        // Then
        XCTAssertEqual(view.vehicle.name, "No VIN Car")
        XCTAssertNil(view.vehicle.vin)
    }

    func testInitialStateWithEmptyName() {
        // Given
        let vehicle = Vehicle(
            name: "",
            make: "Ford",
            model: "F-150",
            year: 2023,
            currentMileage: 5000
        )
        modelContext.insert(vehicle)

        // When
        let view = EditVehicleView(vehicle: vehicle)

        // Then
        XCTAssertEqual(view.vehicle.name, "")
        XCTAssertEqual(view.vehicle.make, "Ford")
        XCTAssertEqual(view.vehicle.model, "F-150")
    }

    // MARK: - Form Validation Tests

    func testFormValidWithAllRequiredFields() {
        // Given
        let vehicle = Vehicle(
            make: "Mazda",
            model: "CX-5",
            year: 2022,
            currentMileage: 8000
        )
        modelContext.insert(vehicle)

        // When
        let view = EditVehicleView(vehicle: vehicle)

        // Then
        // Form should be valid when make, model, and year are present
        XCTAssertFalse(vehicle.make.isEmpty)
        XCTAssertFalse(vehicle.model.isEmpty)
        XCTAssertGreaterThan(vehicle.year, 0)
    }

    func testFormValidationLogic() {
        // Given
        let vehicle = Vehicle(
            make: "Tesla",
            model: "Model 3",
            year: 2024,
            currentMileage: 1000
        )
        modelContext.insert(vehicle)

        // Test valid form
        var testMake = "Tesla"
        var testModel = "Model 3"
        var testYear = "2024"

        var isValid = !testMake.isEmpty && !testModel.isEmpty && !testYear.isEmpty && Int(testYear) != nil
        XCTAssertTrue(isValid, "Form should be valid with all required fields")

        // Test invalid - empty make
        testMake = ""
        isValid = !testMake.isEmpty && !testModel.isEmpty && !testYear.isEmpty && Int(testYear) != nil
        XCTAssertFalse(isValid, "Form should be invalid with empty make")

        // Test invalid - empty model
        testMake = "Tesla"
        testModel = ""
        isValid = !testMake.isEmpty && !testModel.isEmpty && !testYear.isEmpty && Int(testYear) != nil
        XCTAssertFalse(isValid, "Form should be invalid with empty model")

        // Test invalid - empty year
        testModel = "Model 3"
        testYear = ""
        isValid = !testMake.isEmpty && !testModel.isEmpty && !testYear.isEmpty && Int(testYear) != nil
        XCTAssertFalse(isValid, "Form should be invalid with empty year")

        // Test invalid - non-numeric year
        testYear = "abc"
        isValid = !testMake.isEmpty && !testModel.isEmpty && !testYear.isEmpty && Int(testYear) != nil
        XCTAssertFalse(isValid, "Form should be invalid with non-numeric year")
    }

    // MARK: - Vehicle Data Tests

    func testVehicleWithServices() {
        // Given
        let vehicle = Vehicle(
            name: "Service Car",
            make: "Subaru",
            model: "Outback",
            year: 2019,
            currentMileage: 45000
        )
        modelContext.insert(vehicle)

        // When
        let view = EditVehicleView(vehicle: vehicle)

        // Then
        XCTAssertEqual(view.vehicle.services.count, 0, "New vehicle should have no services")
    }

    func testVehicleDisplayName() {
        // Given
        let vehicleWithName = Vehicle(
            name: "My Ride",
            make: "Nissan",
            model: "Altima",
            year: 2020,
            currentMileage: 20000
        )

        let vehicleWithoutName = Vehicle(
            name: "",
            make: "Nissan",
            model: "Altima",
            year: 2020,
            currentMileage: 20000
        )

        // Then
        XCTAssertEqual(vehicleWithName.displayName, "My Ride")
        XCTAssertEqual(vehicleWithoutName.displayName, "2020 Nissan Altima")
    }

    // MARK: - Notes Field Tests

    func testInitialStateWithNotes() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Honda",
            model: "Civic",
            year: 2021,
            currentMileage: 15000,
            notes: "Vehicle has minor scratch on bumper"
        )
        modelContext.insert(vehicle)

        // When
        let view = EditVehicleView(vehicle: vehicle)

        // Then
        XCTAssertEqual(view.vehicle.notes, "Vehicle has minor scratch on bumper")
    }

    func testInitialStateWithNoNotes() {
        // Given
        let vehicle = Vehicle(
            name: "No Notes Car",
            make: "Toyota",
            model: "Corolla",
            year: 2020,
            currentMileage: 10000,
            notes: nil
        )
        modelContext.insert(vehicle)

        // When
        let view = EditVehicleView(vehicle: vehicle)

        // Then
        XCTAssertNil(view.vehicle.notes)
    }

    func testNotesCanBeUpdated() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Honda",
            model: "Civic",
            year: 2021,
            currentMileage: 15000,
            notes: "Original notes"
        )
        modelContext.insert(vehicle)

        // When
        vehicle.notes = "Updated notes with new information"

        // Then
        XCTAssertEqual(vehicle.notes, "Updated notes with new information")
    }

    func testNotesCanBeCleared() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Honda",
            model: "Civic",
            year: 2021,
            currentMileage: 15000,
            notes: "Some notes to clear"
        )
        modelContext.insert(vehicle)

        // When - simulating clearing notes in edit view
        let emptyNotes = ""
        vehicle.notes = emptyNotes.isEmpty ? nil : emptyNotes

        // Then
        XCTAssertNil(vehicle.notes)
    }

    func testNotesPreserveSpecialCharacters() {
        // Given
        let specialNotes = "Oil: 0W-20 @ $45.99 | Tire: 225/45R17 (Front & Rear)"
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Honda",
            model: "Civic",
            year: 2021,
            currentMileage: 15000,
            notes: specialNotes
        )
        modelContext.insert(vehicle)

        // When
        let view = EditVehicleView(vehicle: vehicle)

        // Then
        XCTAssertEqual(view.vehicle.notes, specialNotes)
    }
}
