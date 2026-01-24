//
//  VehicleTests.swift
//  checkpointTests
//
//  Tests for Vehicle model, including notes functionality
//

import XCTest
import SwiftData
@testable import checkpoint

final class VehicleTests: XCTestCase {

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

    // MARK: - Basic Initialization Tests

    func testVehicleInitialization_WithAllParameters() {
        // Given/When
        let vehicle = Vehicle(
            name: "Daily Driver",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500,
            vin: "1HGBH41JXMN109186",
            tireSize: "225/45R17",
            oilType: "0W-20 Synthetic",
            notes: "Bought used, needs new tires soon"
        )

        // Then
        XCTAssertEqual(vehicle.name, "Daily Driver")
        XCTAssertEqual(vehicle.make, "Toyota")
        XCTAssertEqual(vehicle.model, "Camry")
        XCTAssertEqual(vehicle.year, 2022)
        XCTAssertEqual(vehicle.currentMileage, 32500)
        XCTAssertEqual(vehicle.vin, "1HGBH41JXMN109186")
        XCTAssertEqual(vehicle.tireSize, "225/45R17")
        XCTAssertEqual(vehicle.oilType, "0W-20 Synthetic")
        XCTAssertEqual(vehicle.notes, "Bought used, needs new tires soon")
    }

    func testVehicleInitialization_WithMinimalParameters() {
        // Given/When
        let vehicle = Vehicle(
            make: "Honda",
            model: "Civic",
            year: 2020
        )

        // Then
        XCTAssertEqual(vehicle.name, "")
        XCTAssertEqual(vehicle.make, "Honda")
        XCTAssertEqual(vehicle.model, "Civic")
        XCTAssertEqual(vehicle.year, 2020)
        XCTAssertEqual(vehicle.currentMileage, 0)
        XCTAssertNil(vehicle.vin)
        XCTAssertNil(vehicle.tireSize)
        XCTAssertNil(vehicle.oilType)
        XCTAssertNil(vehicle.notes)
    }

    // MARK: - Notes Property Tests

    func testNotes_CanBeSetToString() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: "Test notes content"
        )

        // Then
        XCTAssertEqual(vehicle.notes, "Test notes content")
    }

    func testNotes_CanBeSetToNil() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: nil
        )

        // Then
        XCTAssertNil(vehicle.notes)
    }

    func testNotes_CanBeUpdated() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: "Initial notes"
        )

        // When
        vehicle.notes = "Updated notes"

        // Then
        XCTAssertEqual(vehicle.notes, "Updated notes")
    }

    func testNotes_CanBeCleared() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: "Some notes"
        )

        // When
        vehicle.notes = nil

        // Then
        XCTAssertNil(vehicle.notes)
    }

    func testNotes_CanContainMultilineText() {
        // Given
        let multilineNotes = """
        Line 1: Purchase history
        Line 2: Known issues
        Line 3: Maintenance reminders
        """

        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: multilineNotes
        )

        // Then
        XCTAssertEqual(vehicle.notes, multilineNotes)
        XCTAssertTrue(vehicle.notes?.contains("\n") ?? false, "Notes should contain newlines")
    }

    func testNotes_CanContainSpecialCharacters() {
        // Given
        let specialNotes = "Oil: 0W-20 @ $45.99 | Tire: 225/45R17 (Front & Rear)"

        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: specialNotes
        )

        // Then
        XCTAssertEqual(vehicle.notes, specialNotes)
    }

    func testNotes_CanContainEmptyString() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: ""
        )

        // Then - empty string is different from nil
        XCTAssertEqual(vehicle.notes, "")
        XCTAssertNotNil(vehicle.notes)
    }

    func testNotes_CanContainLongText() {
        // Given
        let longNotes = String(repeating: "This is a long note. ", count: 100)

        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: longNotes
        )

        // Then
        XCTAssertEqual(vehicle.notes, longNotes)
        XCTAssertEqual(vehicle.notes?.count, 2100) // 21 chars * 100
    }

    // MARK: - Display Name Tests

    func testDisplayName_WithCustomName() {
        // Given
        let vehicle = Vehicle(
            name: "Daily Driver",
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertEqual(vehicle.displayName, "Daily Driver")
    }

    func testDisplayName_WithEmptyName() {
        // Given
        let vehicle = Vehicle(
            name: "",
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertEqual(vehicle.displayName, "2022 Toyota Camry")
    }

    // MARK: - Truncated VIN Tests

    func testTruncatedVIN_WithFullVIN() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            vin: "1HGBH41JXMN109186"
        )

        // Then
        XCTAssertEqual(vehicle.truncatedVIN, "...9186")
    }

    func testTruncatedVIN_WithNilVIN() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            vin: nil
        )

        // Then
        XCTAssertNil(vehicle.truncatedVIN)
    }

    func testTruncatedVIN_WithShortVIN() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            vin: "ABC"
        )

        // Then - returns original if less than 4 chars
        XCTAssertEqual(vehicle.truncatedVIN, "ABC")
    }

    // MARK: - Mileage Update Description Tests

    func testMileageUpdateDescription_Never() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            mileageUpdatedAt: nil
        )

        // Then
        XCTAssertEqual(vehicle.mileageUpdateDescription, "Never updated")
    }

    func testMileageUpdateDescription_Today() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            mileageUpdatedAt: Date()
        )

        // Then
        XCTAssertEqual(vehicle.mileageUpdateDescription, "Updated today")
    }

    // MARK: - Photo Data Tests

    func testPhotoData_InitiallyNil() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertNil(vehicle.photoData)
    }

    func testPhotoData_CanBeSet() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )
        let testData = Data([0x00, 0x01, 0x02, 0x03])

        // When
        vehicle.photoData = testData

        // Then
        XCTAssertNotNil(vehicle.photoData)
        XCTAssertEqual(vehicle.photoData, testData)
    }

    func testPhotoData_CanBeCleared() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )
        vehicle.photoData = Data([0x00, 0x01, 0x02, 0x03])

        // When
        vehicle.photoData = nil

        // Then
        XCTAssertNil(vehicle.photoData)
    }

    func testPhoto_ReturnsNilWhenNoData() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertNil(vehicle.photo)
    }

    func testUIImage_ReturnsNilWhenNoData() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertNil(vehicle.uiImage)
    }

    func testUIImage_ReturnsNilForInvalidData() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )
        vehicle.photoData = Data([0x00, 0x01, 0x02, 0x03]) // Invalid image data

        // Then
        XCTAssertNil(vehicle.uiImage)
    }
}
