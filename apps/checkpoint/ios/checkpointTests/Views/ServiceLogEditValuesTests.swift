//
//  ServiceLogEditValuesTests.swift
//  checkpointTests
//
//  Edit Service Log enables Save only when the form would write something
//  different. These pin down what counts as a change.
//

import XCTest
@testable import checkpoint

@MainActor
final class ServiceLogEditValuesTests: XCTestCase {

    private let day = Date(timeIntervalSince1970: 1_750_000_000)

    private func values(
        date: Date? = nil,
        mileage: Int? = 32000,
        cost: String = "45.99",
        category: CostCategory = .maintenance,
        notes: String = "Synthetic"
    ) -> ServiceLogEditValues {
        ServiceLogEditValues(
            performedDate: date ?? day,
            mileage: mileage,
            costText: cost,
            costCategory: category,
            notes: notes
        )
    }

    func test_identicalInputs_areUnchanged() {
        XCTAssertEqual(values(), values())
    }

    func test_equivalentCostText_isUnchanged() {
        XCTAssertEqual(values(cost: "45.99"), values(cost: "45.990"))
    }

    func test_categoryWithoutCost_isUnchanged() {
        // Save drops the category when there is no cost, so flipping it can't
        // be a change worth saving.
        XCTAssertEqual(values(cost: "", category: .maintenance), values(cost: "", category: .repair))
    }

    func test_categoryWithCost_isChange() {
        XCTAssertNotEqual(values(category: .maintenance), values(category: .repair))
    }

    func test_emptyNotes_equalsNilNotes() {
        XCTAssertNil(values(notes: "").notes)
    }

    func test_editedFields_areChanges() {
        XCTAssertNotEqual(values(), values(date: day.addingTimeInterval(86_400)))
        XCTAssertNotEqual(values(), values(mileage: 32500))
        XCTAssertNotEqual(values(), values(cost: "50"))
        XCTAssertNotEqual(values(), values(notes: "Conventional"))
    }

    func test_clearedMileage_isChange() {
        XCTAssertNotEqual(values(), values(mileage: nil))
    }
}
