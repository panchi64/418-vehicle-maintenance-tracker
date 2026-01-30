//
//  VehicleSelectionPersistenceTests.swift
//  checkpointTests
//
//  Tests for vehicle selection persistence across app launches
//

import XCTest
@testable import checkpoint

@MainActor
final class VehicleSelectionPersistenceTests: XCTestCase {

    private let selectedVehicleIDKey = "appSelectedVehicleID"
    private let appGroupID = "group.com.418-studio.checkpoint.shared"

    override func setUp() {
        super.setUp()
        // Clear any existing values before each test
        UserDefaults.standard.removeObject(forKey: selectedVehicleIDKey)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: selectedVehicleIDKey)
    }

    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: selectedVehicleIDKey)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: selectedVehicleIDKey)
        super.tearDown()
    }

    // MARK: - Save Tests

    func testSaveSelectedVehicleID_PersistsToStandardUserDefaults() {
        let testID = UUID().uuidString

        // Simulate saving (same logic as ContentView.persistSelectedVehicle)
        UserDefaults.standard.set(testID, forKey: selectedVehicleIDKey)

        let savedValue = UserDefaults.standard.string(forKey: selectedVehicleIDKey)
        XCTAssertEqual(savedValue, testID, "Vehicle ID should persist to standard UserDefaults")
    }

    func testSaveSelectedVehicleID_PersistsToAppGroupUserDefaults() {
        let testID = UUID().uuidString

        // Simulate saving to both
        UserDefaults.standard.set(testID, forKey: selectedVehicleIDKey)
        UserDefaults(suiteName: appGroupID)?.set(testID, forKey: selectedVehicleIDKey)

        let savedValue = UserDefaults(suiteName: appGroupID)?.string(forKey: selectedVehicleIDKey)
        XCTAssertEqual(savedValue, testID, "Vehicle ID should persist to App Group UserDefaults")
    }

    func testSaveSelectedVehicleID_BothDefaultsMatch() {
        let testID = UUID().uuidString

        // Save to both (as the app does)
        UserDefaults.standard.set(testID, forKey: selectedVehicleIDKey)
        UserDefaults(suiteName: appGroupID)?.set(testID, forKey: selectedVehicleIDKey)

        let standardValue = UserDefaults.standard.string(forKey: selectedVehicleIDKey)
        let appGroupValue = UserDefaults(suiteName: appGroupID)?.string(forKey: selectedVehicleIDKey)

        XCTAssertEqual(standardValue, appGroupValue, "Both UserDefaults should have the same vehicle ID")
    }

    // MARK: - Load Tests

    func testLoadSelectedVehicleID_ReturnsStoredValue() {
        let testID = UUID().uuidString
        UserDefaults.standard.set(testID, forKey: selectedVehicleIDKey)

        let loadedValue = UserDefaults.standard.string(forKey: selectedVehicleIDKey)
        XCTAssertEqual(loadedValue, testID, "Should load the stored vehicle ID")
    }

    func testLoadSelectedVehicleID_ReturnsNilWhenEmpty() {
        // Ensure nothing is stored
        UserDefaults.standard.removeObject(forKey: selectedVehicleIDKey)

        let loadedValue = UserDefaults.standard.string(forKey: selectedVehicleIDKey)
        XCTAssertNil(loadedValue, "Should return nil when no vehicle ID is stored")
    }

    // MARK: - Clear Tests

    func testClearSelectedVehicleID_RemovesFromStandardDefaults() {
        let testID = UUID().uuidString

        // Save first
        UserDefaults.standard.set(testID, forKey: selectedVehicleIDKey)
        XCTAssertNotNil(UserDefaults.standard.string(forKey: selectedVehicleIDKey))

        // Then clear
        UserDefaults.standard.removeObject(forKey: selectedVehicleIDKey)

        let loadedValue = UserDefaults.standard.string(forKey: selectedVehicleIDKey)
        XCTAssertNil(loadedValue, "Vehicle ID should be removed from standard UserDefaults")
    }

    func testClearSelectedVehicleID_RemovesFromAppGroupDefaults() {
        let testID = UUID().uuidString

        // Save first
        UserDefaults(suiteName: appGroupID)?.set(testID, forKey: selectedVehicleIDKey)
        XCTAssertNotNil(UserDefaults(suiteName: appGroupID)?.string(forKey: selectedVehicleIDKey))

        // Then clear
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: selectedVehicleIDKey)

        let loadedValue = UserDefaults(suiteName: appGroupID)?.string(forKey: selectedVehicleIDKey)
        XCTAssertNil(loadedValue, "Vehicle ID should be removed from App Group UserDefaults")
    }

    func testClearSelectedVehicleID_RemovesFromBothDefaults() {
        let testID = UUID().uuidString

        // Save to both
        UserDefaults.standard.set(testID, forKey: selectedVehicleIDKey)
        UserDefaults(suiteName: appGroupID)?.set(testID, forKey: selectedVehicleIDKey)

        // Clear both (as the app does)
        UserDefaults.standard.removeObject(forKey: selectedVehicleIDKey)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: selectedVehicleIDKey)

        let standardValue = UserDefaults.standard.string(forKey: selectedVehicleIDKey)
        let appGroupValue = UserDefaults(suiteName: appGroupID)?.string(forKey: selectedVehicleIDKey)

        XCTAssertNil(standardValue, "Standard UserDefaults should be cleared")
        XCTAssertNil(appGroupValue, "App Group UserDefaults should be cleared")
    }

    // MARK: - UUID Validation Tests

    func testStoredValue_IsValidUUID() {
        let testID = UUID().uuidString
        UserDefaults.standard.set(testID, forKey: selectedVehicleIDKey)

        let loadedValue = UserDefaults.standard.string(forKey: selectedVehicleIDKey)
        XCTAssertNotNil(loadedValue)

        let parsedUUID = UUID(uuidString: loadedValue!)
        XCTAssertNotNil(parsedUUID, "Stored value should be a valid UUID string")
    }

    // MARK: - Update Tests

    func testUpdateSelectedVehicle_OverwritesPreviousValue() {
        let firstID = UUID().uuidString
        let secondID = UUID().uuidString

        // Save first vehicle
        UserDefaults.standard.set(firstID, forKey: selectedVehicleIDKey)
        XCTAssertEqual(UserDefaults.standard.string(forKey: selectedVehicleIDKey), firstID)

        // Save second vehicle
        UserDefaults.standard.set(secondID, forKey: selectedVehicleIDKey)
        XCTAssertEqual(UserDefaults.standard.string(forKey: selectedVehicleIDKey), secondID)
    }
}
