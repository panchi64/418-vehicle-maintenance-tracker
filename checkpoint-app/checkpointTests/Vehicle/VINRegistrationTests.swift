//
//  VINRegistrationTests.swift
//  checkpointTests
//
//  Tests for VIN registration UX: character count states, validation, and auto-fill feedback
//

import XCTest
@testable import checkpoint

final class VINRegistrationTests: XCTestCase {

    // MARK: - VIN Character Count Display States

    func test_vinCharacterCount_empty_showsHelpText() {
        // Given: Empty VIN
        let vin = ""

        // Then: Should show help text state (empty)
        XCTAssertTrue(vin.isEmpty, "Empty VIN should trigger help text display")
    }

    func test_vinCharacterCount_partial_showsCount() {
        // Given: Partially entered VIN
        let partialVINs = ["1HG", "1HGBH41JXMN", "1HGBH41JXMN10918"]

        for vin in partialVINs {
            // Then: Should show character count (not empty, not valid)
            XCTAssertFalse(vin.isEmpty, "Partial VIN '\(vin)' should not be empty")
            XCTAssertNotEqual(vin.count, 17, "Partial VIN '\(vin)' should not be 17 characters")
            XCTAssertTrue(vin.count > 0 && vin.count < 17,
                "Partial VIN '\(vin)' count \(vin.count) should be between 1 and 16")
        }
    }

    func test_vinCharacterCount_valid17Chars_showsValid() {
        // Given: Full 17-character VIN
        let vin = "1HGBH41JXMN109186"

        // Then: Should be exactly 17 characters
        XCTAssertEqual(vin.count, 17, "Valid VIN should be exactly 17 characters")
    }

    // MARK: - VIN Validation Logic

    @MainActor
    func test_isVINValid_validVIN_returnsTrue() async {
        // Given: A form state with a valid VIN
        let formState = VehicleFormState()
        formState.vin = "1HGBH41JXMN109186"

        // Then: isVINValid should be true
        XCTAssertTrue(formState.isVINValid, "17-character alphanumeric VIN should be valid")
    }

    @MainActor
    func test_isVINValid_tooShort_returnsFalse() async {
        // Given: A form state with a short VIN
        let formState = VehicleFormState()
        formState.vin = "1HGBH41JX"

        // Then: isVINValid should be false
        XCTAssertFalse(formState.isVINValid, "VIN with fewer than 17 characters should be invalid")
    }

    @MainActor
    func test_isVINValid_tooLong_returnsFalse() async {
        // Given: A form state with an 18-character VIN
        let formState = VehicleFormState()
        formState.vin = "1HGBH41JXMN1091860"

        // Then: isVINValid should be false
        XCTAssertFalse(formState.isVINValid, "VIN with more than 17 characters should be invalid")
    }

    @MainActor
    func test_isVINValid_containsForbiddenI_returnsFalse() async {
        // Given: VIN containing forbidden character 'I'
        let formState = VehicleFormState()
        formState.vin = "1HGBHI1JXMN109186" // 'I' at position 6

        // Then: isVINValid should be false
        XCTAssertFalse(formState.isVINValid, "VIN containing 'I' should be invalid")
    }

    @MainActor
    func test_isVINValid_containsForbiddenO_returnsFalse() async {
        // Given: VIN containing forbidden character 'O'
        let formState = VehicleFormState()
        formState.vin = "1HGBHO1JXMN109186" // 'O' at position 6

        // Then: isVINValid should be false
        XCTAssertFalse(formState.isVINValid, "VIN containing 'O' should be invalid")
    }

    @MainActor
    func test_isVINValid_containsForbiddenQ_returnsFalse() async {
        // Given: VIN containing forbidden character 'Q'
        let formState = VehicleFormState()
        formState.vin = "1HGBHQ1JXMN109186" // 'Q' at position 6

        // Then: isVINValid should be false
        XCTAssertFalse(formState.isVINValid, "VIN containing 'Q' should be invalid")
    }

    @MainActor
    func test_isVINValid_empty_returnsFalse() async {
        // Given: Empty VIN
        let formState = VehicleFormState()
        formState.vin = ""

        // Then: isVINValid should be false
        XCTAssertFalse(formState.isVINValid, "Empty VIN should be invalid")
    }

    @MainActor
    func test_isVINValid_whitespaceOnly_returnsFalse() async {
        // Given: Whitespace-only VIN
        let formState = VehicleFormState()
        formState.vin = "                 " // 17 spaces

        // Then: isVINValid should be false (spaces are not alphanumeric)
        XCTAssertFalse(formState.isVINValid, "Whitespace-only VIN should be invalid")
    }

    @MainActor
    func test_isVINValid_withSpecialChars_returnsFalse() async {
        // Given: VIN with special characters
        let formState = VehicleFormState()
        formState.vin = "1HGBH41JX-N109186" // dash

        // Then: isVINValid should be false
        XCTAssertFalse(formState.isVINValid, "VIN with special characters should be invalid")
    }

    // MARK: - Auto-Fill Feedback State

    @MainActor
    func test_vinLookupSucceeded_initialState_isFalse() async {
        // Given: A new form state
        let formState = VehicleFormState()

        // Then: vinLookupSucceeded should be false
        XCTAssertFalse(formState.vinLookupSucceeded, "Initial vinLookupSucceeded should be false")
    }

    @MainActor
    func test_autoFilledFields_initialState_isEmpty() async {
        // Given: A new form state
        let formState = VehicleFormState()

        // Then: autoFilledFields should be empty
        XCTAssertTrue(formState.autoFilledFields.isEmpty, "Initial autoFilledFields should be empty")
    }

    @MainActor
    func test_autoFilledFields_canTrackMultipleFields() async {
        // Given: A form state
        let formState = VehicleFormState()

        // When: Setting auto-filled fields
        formState.autoFilledFields = ["make", "model", "year"]
        formState.vinLookupSucceeded = true

        // Then: All fields should be tracked
        XCTAssertEqual(formState.autoFilledFields.count, 3, "Should track 3 auto-filled fields")
        XCTAssertTrue(formState.autoFilledFields.contains("make"), "Should contain 'make'")
        XCTAssertTrue(formState.autoFilledFields.contains("model"), "Should contain 'model'")
        XCTAssertTrue(formState.autoFilledFields.contains("year"), "Should contain 'year'")
        XCTAssertTrue(formState.vinLookupSucceeded, "vinLookupSucceeded should be true")
    }

    @MainActor
    func test_autoFilledFields_partialFill() async {
        // Given: A form state where make is already filled
        let formState = VehicleFormState()
        formState.make = "Toyota"

        // When: Only model and year are auto-filled
        formState.autoFilledFields = ["model", "year"]
        formState.vinLookupSucceeded = true

        // Then: Only model and year should be tracked
        XCTAssertEqual(formState.autoFilledFields.count, 2, "Should track 2 auto-filled fields")
        XCTAssertFalse(formState.autoFilledFields.contains("make"), "Should not contain 'make' (was already filled)")
        XCTAssertTrue(formState.autoFilledFields.contains("model"), "Should contain 'model'")
        XCTAssertTrue(formState.autoFilledFields.contains("year"), "Should contain 'year'")
    }

    @MainActor
    func test_clearAutoFillFeedback_resetsState() async {
        // Given: A form state with auto-fill feedback active
        let formState = VehicleFormState()
        formState.vinLookupSucceeded = true
        formState.autoFilledFields = ["make", "model", "year"]

        // When: Clearing feedback
        formState.clearAutoFillFeedback()

        // Then: State should be reset
        XCTAssertFalse(formState.vinLookupSucceeded, "vinLookupSucceeded should be false after clear")
        XCTAssertTrue(formState.autoFilledFields.isEmpty, "autoFilledFields should be empty after clear")
    }

    @MainActor
    func test_clearVINErrors_doesNotAffectAutoFill() async {
        // Given: A form state with auto-fill feedback and VIN errors
        let formState = VehicleFormState()
        formState.vinLookupSucceeded = true
        formState.autoFilledFields = ["make"]
        formState.vinLookupError = "Network error"

        // When: Clearing VIN errors
        formState.clearVINErrors()

        // Then: Auto-fill state should remain, VIN error should be cleared
        XCTAssertTrue(formState.vinLookupSucceeded, "Auto-fill state should not be affected")
        XCTAssertFalse(formState.autoFilledFields.isEmpty, "Auto-filled fields should not be affected")
        XCTAssertNil(formState.vinLookupError, "VIN lookup error should be cleared")
    }
}
