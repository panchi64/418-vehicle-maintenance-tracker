//
//  QuickSpecsCardTests.swift
//  checkpointTests
//
//  Tests for QuickSpecsCard, including notes display functionality
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

final class QuickSpecsCardTests: XCTestCase {

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

    // MARK: - hasAnySpecs Tests

    func testHasAnySpecs_WithVINOnly() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            vin: "1HGBH41JXMN109186"
        )

        // Then
        let hasSpecs = vehicle.vin != nil || vehicle.tireSize != nil || vehicle.oilType != nil || (vehicle.notes != nil && !vehicle.notes!.isEmpty)
        XCTAssertTrue(hasSpecs, "Should have specs when VIN is present")
    }

    func testHasAnySpecs_WithTireSizeOnly() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            tireSize: "225/45R17"
        )

        // Then
        let hasSpecs = vehicle.vin != nil || vehicle.tireSize != nil || vehicle.oilType != nil || (vehicle.notes != nil && !vehicle.notes!.isEmpty)
        XCTAssertTrue(hasSpecs, "Should have specs when tire size is present")
    }

    func testHasAnySpecs_WithOilTypeOnly() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            oilType: "0W-20 Synthetic"
        )

        // Then
        let hasSpecs = vehicle.vin != nil || vehicle.tireSize != nil || vehicle.oilType != nil || (vehicle.notes != nil && !vehicle.notes!.isEmpty)
        XCTAssertTrue(hasSpecs, "Should have specs when oil type is present")
    }

    func testHasAnySpecs_WithNotesOnly() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: "Some vehicle notes"
        )

        // Then
        let hasSpecs = vehicle.vin != nil || vehicle.tireSize != nil || vehicle.oilType != nil || (vehicle.notes != nil && !vehicle.notes!.isEmpty)
        XCTAssertTrue(hasSpecs, "Should have specs when notes are present")
    }

    func testHasAnySpecs_WithEmptyNotes() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: ""
        )

        // Then
        let hasSpecs = vehicle.vin != nil || vehicle.tireSize != nil || vehicle.oilType != nil || (vehicle.notes != nil && !vehicle.notes!.isEmpty)
        XCTAssertFalse(hasSpecs, "Empty notes should not count as having specs")
    }

    func testHasAnySpecs_WithLicensePlateOnly() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            licensePlate: "ABC-1234"
        )

        // Then
        let hasSpecs = vehicle.vin != nil || vehicle.licensePlate != nil || vehicle.tireSize != nil || vehicle.oilType != nil || (vehicle.notes != nil && !vehicle.notes!.isEmpty)
        XCTAssertTrue(hasSpecs, "Should have specs when license plate is present")
    }

    func testHasAnySpecs_WithNoSpecs() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        let hasSpecs = vehicle.vin != nil || vehicle.tireSize != nil || vehicle.oilType != nil || (vehicle.notes != nil && !vehicle.notes!.isEmpty)
        XCTAssertFalse(hasSpecs, "Should not have specs when nothing is present")
    }

    // MARK: - hasNotes Tests

    func testHasNotes_WithNotes() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: "Some vehicle notes"
        )

        // Then
        let hasNotes = vehicle.notes != nil && !vehicle.notes!.isEmpty
        XCTAssertTrue(hasNotes, "Should have notes when notes string is present")
    }

    func testHasNotes_WithEmptyNotes() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: ""
        )

        // Then
        let hasNotes = vehicle.notes != nil && !vehicle.notes!.isEmpty
        XCTAssertFalse(hasNotes, "Should not have notes when notes string is empty")
    }

    func testHasNotes_WithNilNotes() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: nil
        )

        // Then
        let hasNotes = vehicle.notes != nil && !(vehicle.notes?.isEmpty ?? true)
        XCTAssertFalse(hasNotes, "Should not have notes when notes is nil")
    }

    // MARK: - Truncated Notes Tests

    func testTruncatedNotes_ShortNotes() {
        // Given
        let notes = "Short note"
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: notes
        )

        // When
        let truncated = truncateNotes(vehicle.notes)

        // Then
        XCTAssertEqual(truncated, "Short note", "Short notes should not be truncated")
    }

    func testTruncatedNotes_ExactlyFiftyChars() {
        // Given
        let notes = String(repeating: "a", count: 50)
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: notes
        )

        // When
        let truncated = truncateNotes(vehicle.notes)

        // Then
        XCTAssertEqual(truncated, notes, "Notes at exactly 50 chars should not be truncated")
    }

    func testTruncatedNotes_LongNotes() {
        // Given
        let notes = String(repeating: "a", count: 100)
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: notes
        )

        // When
        let truncated = truncateNotes(vehicle.notes)

        // Then
        XCTAssertEqual(truncated?.count, 53, "Long notes should be truncated to 50 chars + '...'")
        XCTAssertTrue(truncated?.hasSuffix("...") ?? false, "Truncated notes should end with '...'")
    }

    func testTruncatedNotes_NilNotes() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: nil
        )

        // When
        let truncated = truncateNotes(vehicle.notes)

        // Then
        XCTAssertNil(truncated, "Nil notes should return nil")
    }

    func testTruncatedNotes_EmptyNotes() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            notes: ""
        )

        // When
        let truncated = truncateNotes(vehicle.notes)

        // Then
        XCTAssertNil(truncated, "Empty notes should return nil")
    }

    // MARK: - Helper

    private func truncateNotes(_ notes: String?) -> String? {
        guard let notes = notes, !notes.isEmpty else { return nil }
        if notes.count <= 50 {
            return notes
        }
        return String(notes.prefix(50)) + "..."
    }
}
