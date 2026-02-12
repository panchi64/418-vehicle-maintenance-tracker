//
//  FormattersTests.swift
//  checkpointTests
//
//  Tests for Formatters mileage methods with distance unit support
//

import XCTest
@testable import checkpoint

@MainActor
final class FormattersTests: XCTestCase {

    private let unitKey = "distanceUnit"
    private let appGroupID = AppGroupConstants.iPhoneWidget

    override func setUp() {
        super.setUp()
        // Reset to miles before each test
        DistanceSettings.shared.unit = .miles
    }

    override func tearDown() {
        // Reset to miles after tests
        DistanceSettings.shared.unit = .miles
        super.tearDown()
    }

    // MARK: - Mileage Formatting (Miles)

    func testMileageFormatWithMiles() {
        DistanceSettings.shared.unit = .miles

        let result = Formatters.mileage(12345)
        XCTAssertEqual(result, "12,345 mi")
    }

    func testMileageDisplayWithMiles() {
        DistanceSettings.shared.unit = .miles

        let result = Formatters.mileageDisplay(12345)
        XCTAssertEqual(result, "12,345_MI")
    }

    func testMileageNumberWithMiles() {
        DistanceSettings.shared.unit = .miles

        let result = Formatters.mileageNumber(12345)
        XCTAssertEqual(result, "12,345")
    }

    // MARK: - Mileage Formatting (Kilometers)

    func testMileageFormatWithKilometers() {
        DistanceSettings.shared.unit = .kilometers

        // 12345 miles = ~19,867 km
        let result = Formatters.mileage(12345)
        XCTAssertEqual(result, "19,867 km")
    }

    func testMileageDisplayWithKilometers() {
        DistanceSettings.shared.unit = .kilometers

        // 12345 miles = ~19,867 km
        let result = Formatters.mileageDisplay(12345)
        XCTAssertEqual(result, "19,867_KM")
    }

    func testMileageNumberWithKilometers() {
        DistanceSettings.shared.unit = .kilometers

        // 12345 miles = ~19,867 km
        let result = Formatters.mileageNumber(12345)
        XCTAssertEqual(result, "19,867")
    }

    // MARK: - Explicit Unit Methods

    func testMileageWithExplicitUnit() {
        // Should use explicit unit regardless of settings
        DistanceSettings.shared.unit = .miles

        let kmResult = Formatters.mileage(100, unit: .kilometers)
        XCTAssertEqual(kmResult, "161 km")

        let miResult = Formatters.mileage(100, unit: .miles)
        XCTAssertEqual(miResult, "100 mi")
    }

    func testMileageDisplayWithExplicitUnit() {
        DistanceSettings.shared.unit = .miles

        let kmResult = Formatters.mileageDisplay(100, unit: .kilometers)
        XCTAssertEqual(kmResult, "161_KM")

        let miResult = Formatters.mileageDisplay(100, unit: .miles)
        XCTAssertEqual(miResult, "100_MI")
    }

    func testMileageNumberWithExplicitUnit() {
        DistanceSettings.shared.unit = .miles

        let kmResult = Formatters.mileageNumber(100, unit: .kilometers)
        XCTAssertEqual(kmResult, "161")

        let miResult = Formatters.mileageNumber(100, unit: .miles)
        XCTAssertEqual(miResult, "100")
    }

    // MARK: - Auto-Detection Tests

    func testAutoDetectionChangesWithSettings() {
        // Start with miles
        DistanceSettings.shared.unit = .miles
        let milesResult = Formatters.mileage(1000)
        XCTAssertTrue(milesResult.contains("mi"))

        // Switch to kilometers
        DistanceSettings.shared.unit = .kilometers
        let kmResult = Formatters.mileage(1000)
        XCTAssertTrue(kmResult.contains("km"))
    }

    // MARK: - Edge Cases

    func testZeroMileage() {
        DistanceSettings.shared.unit = .miles
        XCTAssertEqual(Formatters.mileage(0), "0 mi")

        DistanceSettings.shared.unit = .kilometers
        XCTAssertEqual(Formatters.mileage(0), "0 km")
    }

    func testLargeNumbers() {
        DistanceSettings.shared.unit = .miles
        let result = Formatters.mileage(1_000_000)
        XCTAssertEqual(result, "1,000,000 mi")
    }

    // MARK: - Estimated Mileage Tests

    func testEstimatedMileage_WithMiles_AddsTildaPrefix() {
        DistanceSettings.shared.unit = .miles

        let result = Formatters.estimatedMileage(32847)
        XCTAssertEqual(result, "~32,847")
    }

    func testEstimatedMileage_WithKilometers_AddsTildaPrefix() {
        DistanceSettings.shared.unit = .kilometers

        // 32847 miles = ~52,862 km (rounded)
        let result = Formatters.estimatedMileage(32847)
        XCTAssertEqual(result, "~52,862")
    }

    func testEstimatedMileage_ExplicitUnit_UsesProvidedUnit() {
        // Should use explicit unit regardless of settings
        DistanceSettings.shared.unit = .miles

        let kmResult = Formatters.estimatedMileage(100, unit: .kilometers)
        XCTAssertEqual(kmResult, "~161")

        let miResult = Formatters.estimatedMileage(100, unit: .miles)
        XCTAssertEqual(miResult, "~100")
    }

    func testEstimatedMileage_ZeroValue_ReturnsTildaZero() {
        DistanceSettings.shared.unit = .miles
        XCTAssertEqual(Formatters.estimatedMileage(0), "~0")
    }
}
