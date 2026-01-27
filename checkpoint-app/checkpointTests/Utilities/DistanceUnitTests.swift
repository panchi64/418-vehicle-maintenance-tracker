//
//  DistanceUnitTests.swift
//  checkpointTests
//
//  Tests for DistanceUnit conversion and display properties
//

import XCTest
@testable import checkpoint

final class DistanceUnitTests: XCTestCase {

    // MARK: - Conversion Tests

    func testMilesToKilometersConversion() {
        let unit = DistanceUnit.kilometers

        // 100 miles should be approximately 161 km
        let result = unit.fromMiles(100)
        XCTAssertEqual(result, 161, "100 miles should convert to 161 km")

        // 1000 miles should be approximately 1609 km
        let result2 = unit.fromMiles(1000)
        XCTAssertEqual(result2, 1609, "1000 miles should convert to 1609 km")
    }

    func testMilesStaysAsMiles() {
        let unit = DistanceUnit.miles

        XCTAssertEqual(unit.fromMiles(100), 100, "Miles should remain unchanged")
        XCTAssertEqual(unit.fromMiles(50000), 50000, "Miles should remain unchanged")
    }

    func testKilometersToMilesConversion() {
        let unit = DistanceUnit.kilometers

        // 100 km should be approximately 62 miles
        let result = unit.toMiles(100)
        XCTAssertEqual(result, 62, "100 km should convert to 62 miles")

        // 161 km should be approximately 100 miles
        let result2 = unit.toMiles(161)
        XCTAssertEqual(result2, 100, "161 km should convert to 100 miles")
    }

    func testMilesToMilesConversion() {
        let unit = DistanceUnit.miles

        XCTAssertEqual(unit.toMiles(100), 100, "Miles input should remain unchanged")
        XCTAssertEqual(unit.toMiles(50000), 50000, "Miles input should remain unchanged")
    }

    func testRoundTripConversion() {
        let unit = DistanceUnit.kilometers
        let originalMiles = 100

        // Convert miles to km, then back to miles
        let asKm = unit.fromMiles(originalMiles)  // 161
        let backToMiles = unit.toMiles(asKm)      // should be close to 100

        // Round trip should be within 1% of original
        let difference = abs(backToMiles - originalMiles)
        let percentDifference = Double(difference) / Double(originalMiles) * 100
        XCTAssertLessThan(percentDifference, 1.0, "Round trip should be within 1%")
    }

    func testLargeNumberConversion() {
        let unit = DistanceUnit.kilometers

        // 100,000 miles should convert properly
        let result = unit.fromMiles(100_000)
        XCTAssertEqual(result, 160_934, "100,000 miles should be approximately 160,934 km")
    }

    func testZeroConversion() {
        XCTAssertEqual(DistanceUnit.miles.fromMiles(0), 0)
        XCTAssertEqual(DistanceUnit.kilometers.fromMiles(0), 0)
        XCTAssertEqual(DistanceUnit.miles.toMiles(0), 0)
        XCTAssertEqual(DistanceUnit.kilometers.toMiles(0), 0)
    }

    // MARK: - Display Properties Tests

    func testMilesAbbreviations() {
        let unit = DistanceUnit.miles

        XCTAssertEqual(unit.abbreviation, "mi")
        XCTAssertEqual(unit.uppercaseAbbreviation, "MI")
        XCTAssertEqual(unit.fullName, "miles")
        XCTAssertEqual(unit.displayName, "Miles")
    }

    func testKilometersAbbreviations() {
        let unit = DistanceUnit.kilometers

        XCTAssertEqual(unit.abbreviation, "km")
        XCTAssertEqual(unit.uppercaseAbbreviation, "KM")
        XCTAssertEqual(unit.fullName, "kilometers")
        XCTAssertEqual(unit.displayName, "Kilometers")
    }

    // MARK: - Enum Tests

    func testAllCasesContainsBothUnits() {
        XCTAssertEqual(DistanceUnit.allCases.count, 2)
        XCTAssertTrue(DistanceUnit.allCases.contains(.miles))
        XCTAssertTrue(DistanceUnit.allCases.contains(.kilometers))
    }

    func testRawValues() {
        XCTAssertEqual(DistanceUnit.miles.rawValue, "miles")
        XCTAssertEqual(DistanceUnit.kilometers.rawValue, "kilometers")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(DistanceUnit(rawValue: "miles"), .miles)
        XCTAssertEqual(DistanceUnit(rawValue: "kilometers"), .kilometers)
        XCTAssertNil(DistanceUnit(rawValue: "invalid"))
    }

    // MARK: - Double Conversion Tests

    func testDoubleConversion() {
        let unit = DistanceUnit.kilometers

        let result = unit.fromMiles(100.0)
        XCTAssertEqual(result, 160.934, accuracy: 0.001)

        let backToMiles = unit.toMiles(160.934)
        XCTAssertEqual(backToMiles, 100.0, accuracy: 0.01)
    }
}
