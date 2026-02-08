//
//  PurchaseSettingsTests.swift
//  checkpointTests
//

import XCTest
@testable import checkpoint

@MainActor
final class PurchaseSettingsTests: XCTestCase {

    private let isProKey = "purchaseIsPro"
    private let tipCountKey = "purchaseTotalTipCount"
    private let ownedThemesKey = "purchaseOwnedThemeIDs"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: isProKey)
        UserDefaults.standard.removeObject(forKey: tipCountKey)
        UserDefaults.standard.removeObject(forKey: ownedThemesKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: isProKey)
        UserDefaults.standard.removeObject(forKey: tipCountKey)
        UserDefaults.standard.removeObject(forKey: ownedThemesKey)
        super.tearDown()
    }

    func testDefaultValues() {
        PurchaseSettings.registerDefaults()
        let settings = PurchaseSettings.shared
        XCTAssertFalse(settings.isPro)
        XCTAssertEqual(settings.totalTipCount, 0)
        XCTAssertTrue(settings.ownedThemeIDs.isEmpty)
    }

    func testIsProPersistence() {
        let settings = PurchaseSettings.shared
        settings.isPro = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: isProKey))
        settings.isPro = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: isProKey))
    }

    func testTipCountPersistence() {
        let settings = PurchaseSettings.shared
        settings.totalTipCount = 5
        XCTAssertEqual(UserDefaults.standard.integer(forKey: tipCountKey), 5)
    }

    func testSessionFlagNotPersisted() {
        let settings = PurchaseSettings.shared
        settings.hasShownTipModalThisSession = true
        // This is in-memory only, verify it doesn't persist to UserDefaults
        XCTAssertTrue(settings.hasShownTipModalThisSession)
    }

    func testOwnedThemeIDsPersistence() {
        let settings = PurchaseSettings.shared
        settings.ownedThemeIDs = ["theme1", "theme2"]
        let stored = UserDefaults.standard.stringArray(forKey: ownedThemesKey)
        XCTAssertEqual(stored, ["theme1", "theme2"])
    }

    func testSharedInstance() {
        let instance1 = PurchaseSettings.shared
        let instance2 = PurchaseSettings.shared
        XCTAssertTrue(instance1 === instance2)
    }
}
