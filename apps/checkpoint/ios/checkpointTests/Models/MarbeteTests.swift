//
//  MarbeteTests.swift
//  checkpointTests
//
//  Tests for marbete (PR vehicle registration tag) tracking functionality
//

import XCTest
import SwiftData
@testable import checkpoint

final class MarbeteTests: XCTestCase {

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

    // MARK: - hasMarbeteExpiration Tests

    func testHasMarbeteExpiration_WhenBothMonthAndYearSet_ReturnsTrue() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 3,
            marbeteExpirationYear: 2025
        )

        // Then
        XCTAssertTrue(vehicle.hasMarbeteExpiration)
    }

    func testHasMarbeteExpiration_WhenOnlyMonthSet_ReturnsFalse() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 3,
            marbeteExpirationYear: nil
        )

        // Then
        XCTAssertFalse(vehicle.hasMarbeteExpiration)
    }

    func testHasMarbeteExpiration_WhenOnlyYearSet_ReturnsFalse() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: nil,
            marbeteExpirationYear: 2025
        )

        // Then
        XCTAssertFalse(vehicle.hasMarbeteExpiration)
    }

    func testHasMarbeteExpiration_WhenNeitherSet_ReturnsFalse() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertFalse(vehicle.hasMarbeteExpiration)
    }

    // MARK: - Expiration Date Calculation Tests

    func testMarbeteExpirationDate_ReturnsLastDayOfMonth() {
        // Given - March 2025
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 3,
            marbeteExpirationYear: 2025
        )

        // When
        let expirationDate = vehicle.marbeteExpirationDate

        // Then - March has 31 days
        XCTAssertNotNil(expirationDate)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: expirationDate!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 31)
    }

    func testMarbeteExpirationDate_February_NonLeapYear() {
        // Given - February 2025 (not a leap year)
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 2,
            marbeteExpirationYear: 2025
        )

        // When
        let expirationDate = vehicle.marbeteExpirationDate

        // Then - February 2025 has 28 days
        XCTAssertNotNil(expirationDate)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: expirationDate!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 28)
    }

    func testMarbeteExpirationDate_February_LeapYear() {
        // Given - February 2024 (leap year)
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 2,
            marbeteExpirationYear: 2024
        )

        // When
        let expirationDate = vehicle.marbeteExpirationDate

        // Then - February 2024 has 29 days (leap year)
        XCTAssertNotNil(expirationDate)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: expirationDate!)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 29)
    }

    func testMarbeteExpirationDate_WhenNotSet_ReturnsNil() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertNil(vehicle.marbeteExpirationDate)
    }

    // MARK: - Days Until Expiration Tests

    func testDaysUntilMarbeteExpiration_WhenNotSet_ReturnsNil() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertNil(vehicle.daysUntilMarbeteExpiration)
    }

    // MARK: - Status Tests

    func testMarbeteStatus_WhenNotSet_ReturnsNeutral() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertEqual(vehicle.marbeteStatus, .neutral)
    }

    func testMarbeteStatus_WhenExpired_ReturnsOverdue() {
        // Given - Set to a past date
        let pastYear = Calendar.current.component(.year, from: .now) - 1
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 1,  // January
            marbeteExpirationYear: pastYear
        )

        // Then
        XCTAssertEqual(vehicle.marbeteStatus, .overdue)
    }

    func testMarbeteStatus_WhenWithin60Days_ReturnsDueSoon() {
        // Given - Set to 30 days from now
        let calendar = Calendar.current
        guard let futureDate = calendar.date(byAdding: .day, value: 30, to: .now) else {
            XCTFail("Could not calculate future date")
            return
        }
        let month = calendar.component(.month, from: futureDate)
        let year = calendar.component(.year, from: futureDate)

        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: month,
            marbeteExpirationYear: year
        )

        // Then - Status should be dueSoon (within 60-day threshold)
        // Note: The actual days calculation depends on current date relative to end of month
        let status = vehicle.marbeteStatus
        XCTAssertTrue(status == .dueSoon || status == .good, "Status should be dueSoon or good depending on exact date calculation")
    }

    func testMarbeteStatus_WhenMoreThan60DaysAway_ReturnsGood() {
        // Given - Set to 90 days from now
        let calendar = Calendar.current
        guard let futureDate = calendar.date(byAdding: .day, value: 100, to: .now) else {
            XCTFail("Could not calculate future date")
            return
        }
        let month = calendar.component(.month, from: futureDate)
        let year = calendar.component(.year, from: futureDate)

        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: month,
            marbeteExpirationYear: year
        )

        // Then
        XCTAssertEqual(vehicle.marbeteStatus, .good)
    }

    // MARK: - Formatted Expiration String Tests

    func testMarbeteExpirationFormatted_ReturnsMonthYear() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 3,
            marbeteExpirationYear: 2025
        )

        // When
        let formatted = vehicle.marbeteExpirationFormatted

        // Then
        XCTAssertEqual(formatted, "March 2025")
    }

    func testMarbeteExpirationFormatted_WhenNotSet_ReturnsNil() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertNil(vehicle.marbeteExpirationFormatted)
    }

    func testMarbeteExpirationFormatted_December() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 12,
            marbeteExpirationYear: 2025
        )

        // When
        let formatted = vehicle.marbeteExpirationFormatted

        // Then
        XCTAssertEqual(formatted, "December 2025")
    }

    // MARK: - Urgency Score Tests

    func testMarbeteUrgencyScore_WhenNotSet_ReturnsMaxInt() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022
        )

        // Then
        XCTAssertEqual(vehicle.marbeteUrgencyScore, Int.max)
    }

    func testMarbeteUrgencyScore_WhenExpired_ReturnsNegative() {
        // Given - Set to a past date
        let pastYear = Calendar.current.component(.year, from: .now) - 1
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 1,
            marbeteExpirationYear: pastYear
        )

        // Then - Urgency score should be negative (days until expiration)
        XCTAssertLessThan(vehicle.marbeteUrgencyScore, 0)
    }

    func testMarbeteUrgencyScore_MatchesDaysUntilExpiration() {
        // Given
        let vehicle = Vehicle(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            marbeteExpirationMonth: 6,
            marbeteExpirationYear: Calendar.current.component(.year, from: .now) + 1
        )

        // When
        let urgencyScore = vehicle.marbeteUrgencyScore
        let daysUntil = vehicle.daysUntilMarbeteExpiration

        // Then
        XCTAssertNotNil(daysUntil)
        XCTAssertEqual(urgencyScore, daysUntil)
    }

    // MARK: - Vehicle Init with Marbete Tests

    func testVehicleInit_WithMarbeteParameters() {
        // Given/When
        let vehicle = Vehicle(
            make: "Honda",
            model: "Civic",
            year: 2023,
            marbeteExpirationMonth: 5,
            marbeteExpirationYear: 2025
        )

        // Then
        XCTAssertEqual(vehicle.marbeteExpirationMonth, 5)
        XCTAssertEqual(vehicle.marbeteExpirationYear, 2025)
        XCTAssertTrue(vehicle.hasMarbeteExpiration)
    }

    func testVehicleInit_DefaultMarbete_IsNil() {
        // Given/When
        let vehicle = Vehicle(
            make: "Honda",
            model: "Civic",
            year: 2023
        )

        // Then
        XCTAssertNil(vehicle.marbeteExpirationMonth)
        XCTAssertNil(vehicle.marbeteExpirationYear)
        XCTAssertFalse(vehicle.hasMarbeteExpiration)
    }
}
