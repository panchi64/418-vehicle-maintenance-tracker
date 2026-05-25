//
//  StoreManagerTests.swift
//  checkpointTests
//

import XCTest
@testable import checkpoint

@MainActor
final class StoreManagerTests: XCTestCase {

    func testProductIDValues() {
        XCTAssertEqual(StoreManager.ProductID.proUnlock.rawValue, "pro.unlock")
        XCTAssertEqual(StoreManager.ProductID.tipSmall.rawValue, "tip.small")
        XCTAssertEqual(StoreManager.ProductID.tipMedium.rawValue, "tip.medium")
        XCTAssertEqual(StoreManager.ProductID.tipLarge.rawValue, "tip.large")
    }

    func testProductIDConsumable() {
        XCTAssertFalse(StoreManager.ProductID.proUnlock.isConsumable)
        XCTAssertTrue(StoreManager.ProductID.tipSmall.isConsumable)
        XCTAssertTrue(StoreManager.ProductID.tipMedium.isConsumable)
        XCTAssertTrue(StoreManager.ProductID.tipLarge.isConsumable)
    }

    func testAllCasesCount() {
        XCTAssertEqual(StoreManager.ProductID.allCases.count, 4)
    }

    func testSharedInstance() {
        let instance1 = StoreManager.shared
        let instance2 = StoreManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
}
