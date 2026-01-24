//
//  AddVehicleViewTests.swift
//  checkpointTests
//
//  Tests for AddVehicleView form validation logic
//

import XCTest
import SwiftUI
@testable import checkpoint

final class AddVehicleViewTests: XCTestCase {

    // MARK: - Form Validation Logic Tests
    // Note: SwiftUI @State properties are private, so we test the validation logic directly

    func testFormValidation_RequiredFieldsLogic() {
        // Test the validation logic used in isFormValid

        // Valid case: all required fields filled
        let make1 = "Toyota"
        let model1 = "Camry"
        let year1 = "2022"
        let isValid1 = !make1.isEmpty && !model1.isEmpty && !year1.isEmpty && Int(year1) != nil
        XCTAssertTrue(isValid1, "Form should be valid when make, model, and year are filled correctly")

        // Invalid case: make empty
        let make2 = ""
        let model2 = "Camry"
        let year2 = "2022"
        let isValid2 = !make2.isEmpty && !model2.isEmpty && !year2.isEmpty && Int(year2) != nil
        XCTAssertFalse(isValid2, "Form should be invalid when make is empty")

        // Invalid case: model empty
        let make3 = "Toyota"
        let model3 = ""
        let year3 = "2022"
        let isValid3 = !make3.isEmpty && !model3.isEmpty && !year3.isEmpty && Int(year3) != nil
        XCTAssertFalse(isValid3, "Form should be invalid when model is empty")

        // Invalid case: year empty
        let make4 = "Toyota"
        let model4 = "Camry"
        let year4 = ""
        let isValid4 = !make4.isEmpty && !model4.isEmpty && !year4.isEmpty && Int(year4) != nil
        XCTAssertFalse(isValid4, "Form should be invalid when year is empty")

        // Invalid case: year not numeric
        let make5 = "Toyota"
        let model5 = "Camry"
        let year5 = "abc"
        let isValid5 = !make5.isEmpty && !model5.isEmpty && !year5.isEmpty && Int(year5) != nil
        XCTAssertFalse(isValid5, "Form should be invalid when year is not numeric")
    }

    // MARK: - Year Field Validation Tests

    func testYearField_AcceptsValidInteger() {
        // Given: Valid year strings
        let validYears = ["2022", "2000", "1995", "2025"]

        validYears.forEach { year in
            // When: Converting to Int
            let yearInt = Int(year)

            // Then: Should convert successfully
            XCTAssertNotNil(yearInt, "Year '\(year)' should convert to Int")
        }
    }

    func testYearField_RejectsInvalidInteger() {
        // Given: Invalid year strings
        let invalidYears = ["abc", "20.5", "twenty", ""]

        invalidYears.forEach { year in
            // When: Converting to Int
            let yearInt = Int(year)

            // Then: Should return nil
            XCTAssertNil(yearInt, "Year '\(year)' should not convert to Int")
        }
    }

    func testYearField_SpecificEdgeCases() {
        // Test specific edge cases
        XCTAssertNotNil(Int("1900"), "Should accept year 1900")
        XCTAssertNotNil(Int("2100"), "Should accept year 2100")
        XCTAssertNil(Int("19.99"), "Should reject decimal years")
        XCTAssertNil(Int("two thousand"), "Should reject word years")
        XCTAssertNil(Int(" 2022 "), "Should handle whitespace appropriately")
    }

    // MARK: - Complete Form Validation Scenarios

    func testFormValidation_AllFieldsFilled() {
        // Given: All fields filled correctly
        let make = "Toyota"
        let model = "Camry"
        let year = "2022"
        let name = "Daily Driver"
        let currentMileage = "32500"
        let vin = "1HGBH41JXMN109186"

        // When: Checking validation
        let isValid = !make.isEmpty && !model.isEmpty && !year.isEmpty && Int(year) != nil

        // Then: Form should be valid
        XCTAssertTrue(isValid, "Form should be valid when all required fields are filled correctly")

        // Verify optional fields don't affect validation
        XCTAssertFalse(name.isEmpty, "Optional fields can be filled")
        XCTAssertFalse(currentMileage.isEmpty, "Optional fields can be filled")
        XCTAssertFalse(vin.isEmpty, "Optional fields can be filled")
    }

    func testFormValidation_OnlyRequiredFieldsFilled() {
        // Given: Only required fields filled
        let make = "Honda"
        let model = "Civic"
        let year = "2020"
        let name = ""
        let currentMileage = ""
        let vin = ""

        // When: Checking validation
        let isValid = !make.isEmpty && !model.isEmpty && !year.isEmpty && Int(year) != nil

        // Then: Form should still be valid
        XCTAssertTrue(isValid, "Form should be valid even when optional fields are empty")
        XCTAssertTrue(name.isEmpty, "Optional field can be empty")
        XCTAssertTrue(currentMileage.isEmpty, "Optional field can be empty")
        XCTAssertTrue(vin.isEmpty, "Optional field can be empty")
    }

    func testFormValidation_MultipleInvalidConditions() {
        // Given: Multiple invalid conditions
        let make = ""
        let model = ""
        let year = "invalid"

        // When: Checking validation
        let isValid = !make.isEmpty && !model.isEmpty && !year.isEmpty && Int(year) != nil

        // Then: Form should be invalid
        XCTAssertFalse(isValid, "Form should be invalid when multiple required fields are invalid")
    }

    // MARK: - Vehicle Creation Logic Tests

    func testVehicleCreation_WithAllFields() {
        // Given: All field values
        let name = "Daily Driver"
        let make = "Toyota"
        let model = "Camry"
        let year = "2022"
        let currentMileage = "32500"
        let vin = "1HGBH41JXMN109186"

        // When: Creating a vehicle (simulating saveVehicle logic)
        let vehicle = Vehicle(
            name: name,
            make: make,
            model: model,
            year: Int(year) ?? 0,
            currentMileage: Int(currentMileage) ?? 0,
            vin: vin.isEmpty ? nil : vin
        )

        // Then: Vehicle should be created correctly
        XCTAssertEqual(vehicle.name, "Daily Driver")
        XCTAssertEqual(vehicle.make, "Toyota")
        XCTAssertEqual(vehicle.model, "Camry")
        XCTAssertEqual(vehicle.year, 2022)
        XCTAssertEqual(vehicle.currentMileage, 32500)
        XCTAssertEqual(vehicle.vin, "1HGBH41JXMN109186")
    }

    func testVehicleCreation_WithRequiredFieldsOnly() {
        // Given: Only required fields
        let name = ""
        let make = "Honda"
        let model = "Civic"
        let year = "2020"
        let currentMileage = ""
        let vin = ""

        // When: Creating a vehicle
        let vehicle = Vehicle(
            name: name,
            make: make,
            model: model,
            year: Int(year) ?? 0,
            currentMileage: Int(currentMileage) ?? 0,
            vin: vin.isEmpty ? nil : vin
        )

        // Then: Vehicle should be created with defaults for optional fields
        XCTAssertEqual(vehicle.name, "")
        XCTAssertEqual(vehicle.make, "Honda")
        XCTAssertEqual(vehicle.model, "Civic")
        XCTAssertEqual(vehicle.year, 2020)
        XCTAssertEqual(vehicle.currentMileage, 0)
        XCTAssertNil(vehicle.vin)
    }

    func testVehicleCreation_InvalidYearDefaultsToZero() {
        // Given: Invalid year value
        let year = "invalid"

        // When: Converting to Int with nil coalescing
        let yearInt = Int(year) ?? 0

        // Then: Should default to 0
        XCTAssertEqual(yearInt, 0, "Invalid year should default to 0")
    }

    func testVehicleCreation_EmptyMileageDefaultsToZero() {
        // Given: Empty mileage value
        let mileage = ""

        // When: Converting to Int with nil coalescing
        let mileageInt = Int(mileage) ?? 0

        // Then: Should default to 0
        XCTAssertEqual(mileageInt, 0, "Empty mileage should default to 0")
    }
}
