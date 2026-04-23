//
//  ThemeManagerTests.swift
//  checkpointTests
//

import XCTest
@testable import checkpoint

@MainActor
final class ThemeManagerTests: XCTestCase {

    private let activeThemeKey = "activeThemeID"
    private let ownedThemeKey = "ownedThemeIDs"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: activeThemeKey)
        UserDefaults.standard.removeObject(forKey: ownedThemeKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: activeThemeKey)
        UserDefaults.standard.removeObject(forKey: ownedThemeKey)
        super.tearDown()
    }

    func testSharedInstance() {
        let instance1 = ThemeManager.shared
        let instance2 = ThemeManager.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testAllThemesLoaded() {
        let manager = ThemeManager.shared
        XCTAssertEqual(manager.allThemes.count, 8)
    }

    func testDefaultThemeIsActive() {
        ThemeManager.registerDefaults()
        let manager = ThemeManager.shared
        XCTAssertEqual(manager.current.id, "default")
    }

    func testDefaultThemeIsOwned() {
        let manager = ThemeManager.shared
        XCTAssertTrue(manager.isOwned(manager.current))
    }

    func testRegisterDefaults() {
        ThemeManager.registerDefaults()
        let activeID = UserDefaults.standard.string(forKey: activeThemeKey)
        XCTAssertEqual(activeID, "default")
    }
}
