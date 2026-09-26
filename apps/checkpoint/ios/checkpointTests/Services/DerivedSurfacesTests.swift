//
//  DerivedSurfacesTests.swift
//  checkpointTests
//
//  The app icon mirrors the selected vehicle only, so a refresh after a
//  write to another vehicle (Siri can name any) leaves it alone.
//

import XCTest
@testable import checkpoint

@MainActor
final class DerivedSurfacesTests: XCTestCase {
    private let suite = "DerivedSurfacesTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func test_isSelected_matchesThePersistedSelection() {
        let daily = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020)
        let weekend = Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019)
        defaults.set(daily.id.uuidString, forKey: AppGroupConstants.appSelectedVehicleIDKey)

        XCTAssertTrue(DerivedSurfaces.isSelected(daily, defaults: defaults))
        XCTAssertFalse(DerivedSurfaces.isSelected(weekend, defaults: defaults))
    }

    func test_isSelected_noSelectionYet_isAnyVehicle() {
        let daily = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020)
        XCTAssertTrue(DerivedSurfaces.isSelected(daily, defaults: defaults))
    }
}
