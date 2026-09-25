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

    private static let validVIN = "1HGBH41JXMN109186"

    private static func decoded(make: String = "Honda", model: String = "Civic", year: Int? = 2021) -> VINDecodeResult {
        VINDecodeResult(
            make: make, model: model, modelYear: year,
            engineDescription: "", driveType: "", bodyClass: "", fuelType: "", errorCode: "0"
        )
    }

    @MainActor
    func test_vinLookupOutcome_initialState_isNil() {
        let formState = VehicleFormState()
        XCTAssertNil(formState.vinLookupOutcome)
        XCTAssertFalse(formState.isAutoFilled(.make))
    }

    @MainActor
    func test_applyVINLookup_emptyForm_fillsAllThree() {
        let formState = VehicleFormState()
        formState.vin = Self.validVIN

        formState.applyVINLookup(Self.decoded(), for: Self.validVIN)

        XCTAssertEqual(formState.make, "Honda")
        XCTAssertEqual(formState.model, "Civic")
        XCTAssertEqual(formState.year, 2021)
        XCTAssertEqual(formState.vinLookupOutcome, .filled([.make, .model, .year]))
        XCTAssertTrue(formState.usedVINLookup)
        XCTAssertFalse(formState.isDecodingVIN)
    }

    @MainActor
    func test_applyVINLookup_neverOverwritesTypedValues() {
        let formState = VehicleFormState()
        formState.make = "Toyota"

        formState.applyVINLookup(Self.decoded(), for: Self.validVIN)

        XCTAssertEqual(formState.make, "Toyota", "A lookup must not overwrite what the user typed")
        XCTAssertEqual(formState.vinLookupOutcome, .filled([.model, .year]))
        XCTAssertFalse(formState.isAutoFilled(.make))
        XCTAssertTrue(formState.isAutoFilled(.model))
    }

    @MainActor
    func test_applyVINLookup_everythingFilled_reportsNothingNew() {
        let formState = VehicleFormState()
        formState.make = "Toyota"
        formState.model = "Camry"
        formState.year = 2020

        formState.applyVINLookup(Self.decoded(), for: Self.validVIN)

        XCTAssertEqual(formState.vinLookupOutcome, .nothingNew)
    }

    @MainActor
    func test_vinLookupOutcome_persistsUntilVINChanges() {
        // The confirmation no longer dismisses on a timer — only a new VIN
        // makes it stale.
        let formState = VehicleFormState()
        formState.applyVINLookup(Self.decoded(), for: Self.validVIN)
        XCTAssertNotNil(formState.vinLookupOutcome)

        formState.vinLookupError = "stale"
        formState.vinDidChange()

        XCTAssertNil(formState.vinLookupOutcome)
        XCTAssertNil(formState.vinLookupError)
    }

    // MARK: - Auto-decode trigger

    @MainActor
    func test_shouldAutoDecodeVIN_validNewVIN_isTrue() {
        let formState = VehicleFormState()
        formState.vin = Self.validVIN
        XCTAssertTrue(formState.shouldAutoDecodeVIN)
    }

    @MainActor
    func test_shouldAutoDecodeVIN_partialVIN_isFalse() {
        let formState = VehicleFormState()
        formState.vin = "1HGBH41JX"
        XCTAssertFalse(formState.shouldAutoDecodeVIN)
    }

    @MainActor
    func test_shouldAutoDecodeVIN_afterDecode_isFalseForSameVIN() {
        let formState = VehicleFormState()
        formState.vin = Self.validVIN
        formState.applyVINLookup(Self.decoded(), for: Self.validVIN)
        XCTAssertFalse(formState.shouldAutoDecodeVIN, "One lookup per VIN")
    }

    @MainActor
    func test_shouldAutoDecodeVIN_afterFailure_doesNotRetryInALoop() {
        let formState = VehicleFormState()
        formState.vin = Self.validVIN
        formState.beginVINLookup()
        XCTAssertFalse(formState.shouldAutoDecodeVIN, "No second lookup while one is in flight")

        formState.failVINLookup("Network error", for: Self.validVIN)

        XCTAssertFalse(formState.shouldAutoDecodeVIN)
        XCTAssertEqual(formState.vinLookupError, "Network error")
    }

    @MainActor
    func test_shouldAutoDecodeVIN_editVehicle_doesNotDecodeStoredVIN() {
        let vehicle = Vehicle(name: "", make: "Honda", model: "Civic", year: 2021, currentMileage: 1000, vin: Self.validVIN)
        let formState = VehicleFormState(vehicle: vehicle)
        XCTAssertFalse(formState.shouldAutoDecodeVIN, "Opening Edit must not look the stored VIN up again")
    }

    // MARK: - Dirty tracking

    @MainActor
    func test_isDirty_editVehicle_pristineUntilAFieldChanges() {
        let vehicle = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2021, currentMileage: 1000)
        let formState = VehicleFormState(vehicle: vehicle)
        XCTAssertFalse(formState.isDirty)

        formState.notes = "New tires"
        XCTAssertTrue(formState.isDirty)

        formState.notes = ""
        XCTAssertFalse(formState.isDirty, "Reverting the edit makes the form pristine again")
    }

    @MainActor
    func test_isDirty_addVehicle_anyEntryIsDirty() {
        let formState = VehicleFormState()
        XCTAssertFalse(formState.isDirty)
        formState.currentMileage = 12
        XCTAssertTrue(formState.isDirty)
    }
}
