//
//  CostCategoryTests.swift
//  checkpointTests
//
//  Unit tests for CostCategory enum
//

import XCTest
import SwiftUI
@testable import checkpoint

final class CostCategoryTests: XCTestCase {

    // MARK: - Initialization Tests

    func testAllCases() {
        // Given
        let allCases = CostCategory.allCases

        // Then
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.maintenance))
        XCTAssertTrue(allCases.contains(.repair))
        XCTAssertTrue(allCases.contains(.upgrade))
    }

    func testRawValues() {
        // Then
        XCTAssertEqual(CostCategory.maintenance.rawValue, "maintenance")
        XCTAssertEqual(CostCategory.repair.rawValue, "repair")
        XCTAssertEqual(CostCategory.upgrade.rawValue, "upgrade")
    }

    // MARK: - Display Name Tests

    func testDisplayNames() {
        // Then
        XCTAssertEqual(CostCategory.maintenance.displayName, "Maintenance")
        XCTAssertEqual(CostCategory.repair.displayName, "Repair")
        XCTAssertEqual(CostCategory.upgrade.displayName, "Upgrade")
    }

    // MARK: - Icon Tests

    func testIcons() {
        // Then
        XCTAssertEqual(CostCategory.maintenance.icon, "wrench.and.screwdriver")
        XCTAssertEqual(CostCategory.repair.icon, "exclamationmark.triangle")
        XCTAssertEqual(CostCategory.upgrade.icon, "arrow.up.circle")
    }

    // MARK: - Color Tests

    func testColors() {
        // Then - just verify colors are not nil/clear
        XCTAssertNotNil(CostCategory.maintenance.color)
        XCTAssertNotNil(CostCategory.repair.color)
        XCTAssertNotNil(CostCategory.upgrade.color)
    }

    // MARK: - Codable Tests

    func testEncodingDecoding() throws {
        // Given
        let category = CostCategory.maintenance
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // When
        let data = try encoder.encode(category)
        let decoded = try decoder.decode(CostCategory.self, from: data)

        // Then
        XCTAssertEqual(category, decoded)
    }

    func testDecodingFromString() throws {
        // Given
        let json = "\"repair\""
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let category = try decoder.decode(CostCategory.self, from: data)

        // Then
        XCTAssertEqual(category, .repair)
    }

    func testAllCategoriesEncodeDecode() throws {
        // Given
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Then
        for category in CostCategory.allCases {
            let data = try encoder.encode(category)
            let decoded = try decoder.decode(CostCategory.self, from: data)
            XCTAssertEqual(category, decoded)
        }
    }
}
