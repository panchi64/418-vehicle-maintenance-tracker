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

    /// Names and colors read the main-actor `L10n` and theme, so they are
    /// resolved before the (nonisolated) assertion autoclosures.
    @MainActor
    func testDisplayNames() {
        let names = [CostCategory.maintenance, .repair, .upgrade].map(\.displayName)

        XCTAssertEqual(names, ["Maintenance", "Repair", "Upgrade"])
    }

    // MARK: - Icon Tests

    func testIcons() {
        // Then
        XCTAssertEqual(CostCategory.maintenance.icon, "wrench.and.screwdriver")
        XCTAssertEqual(CostCategory.repair.icon, "exclamationmark.triangle")
        XCTAssertEqual(CostCategory.upgrade.icon, "arrow.up.circle")
    }

    // MARK: - Color Tests

    @MainActor
    func testColors() {
        // Then - just verify every category resolves a color
        let colors = CostCategory.allCases.map(\.color)

        XCTAssertEqual(colors.count, CostCategory.allCases.count)
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
