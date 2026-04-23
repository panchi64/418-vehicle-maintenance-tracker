//
//  ServiceLogDetailViewTests.swift
//  checkpointTests
//
//  Tests for ServiceLogDetailView — the detail sheet for a single service log
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceLogDetailViewTests: XCTestCase {

    // MARK: - Log Detail Data Tests

    func testServiceLogDetail_DisplaysServiceName() {
        // Given: A service log linked to a service
        let service = Service(name: "Oil Change", dueDate: nil)
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)

        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Date.now,
            mileageAtService: 32000,
            cost: 45.99,
            costCategory: .maintenance,
            notes: "Synthetic oil used"
        )

        // Then: Log should have correct service reference
        XCTAssertEqual(log.service?.name, "Oil Change")
    }

    func testServiceLogDetail_DisplaysCostAndCategory() {
        // Given: A service log with cost and category
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 30000,
            cost: 285.00,
            costCategory: .repair,
            notes: "Front brake pads replaced"
        )

        // Then: Cost and category should be accessible
        XCTAssertEqual(log.cost, 285.00)
        XCTAssertEqual(log.costCategory, .repair)
        XCTAssertNotNil(log.formattedCost)
        XCTAssertEqual(log.notes, "Front brake pads replaced")
    }

    func testServiceLogDetail_HandlesNilOptionalFields() {
        // Given: A minimal service log with no optional fields
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 25000
        )

        // Then: Optional fields should be nil
        XCTAssertNil(log.service)
        XCTAssertNil(log.cost)
        XCTAssertNil(log.costCategory)
        XCTAssertNil(log.notes)
        XCTAssertNil(log.formattedCost)
        XCTAssertTrue((log.attachments ?? []).isEmpty)
    }

    func testServiceLogDetail_MileageIsAccessible() {
        // Given: A log with mileage
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 45000
        )

        // Then: Mileage should be accessible
        XCTAssertEqual(log.mileageAtService, 45000)
    }

    func testServiceLogDetail_DateIsAccessible() {
        // Given: A log with a specific date
        let date = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        let log = ServiceLog(
            performedDate: date,
            mileageAtService: 32000
        )

        // Then: Date should match
        XCTAssertEqual(log.performedDate, date)
    }

    func testServiceLogDetail_AttachmentsAccessible() {
        // Given: A log (attachments are empty by default)
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000
        )

        // Then: Attachments array should exist and be empty
        XCTAssertTrue((log.attachments ?? []).isEmpty)
    }

    // MARK: - AppState selectedServiceLog Tests
    // Note: AppState selectedServiceLog property is tested in AppStateTests
    // to avoid simulator crashes from @MainActor + @Model interactions

    // MARK: - Tappable Row Tests

    func testServiceLog_HasIdentifiableConformance() {
        // Given: A service log
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000
        )

        // Then: Log should have a unique ID (required for .sheet(item:))
        XCTAssertNotNil(log.id)
    }

    func testServiceLog_DifferentLogsHaveDifferentIDs() {
        // Given: Two service logs
        let log1 = ServiceLog(performedDate: Date.now, mileageAtService: 32000)
        let log2 = ServiceLog(performedDate: Date.now, mileageAtService: 33000)

        // Then: IDs should be different
        XCTAssertNotEqual(log1.id, log2.id)
    }

    func testServiceLog_AllCostCategoriesSupported() {
        // Given: All cost categories
        let categories: [CostCategory] = [.maintenance, .repair, .upgrade]

        for category in categories {
            let log = ServiceLog(
                performedDate: Date.now,
                mileageAtService: 32000,
                cost: 100.00,
                costCategory: category
            )

            // Then: Category should be set correctly
            XCTAssertEqual(log.costCategory, category)
        }
    }
}
