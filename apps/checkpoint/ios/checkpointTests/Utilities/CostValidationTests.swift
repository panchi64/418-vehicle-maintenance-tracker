@testable import checkpoint
import Testing

@Suite("CostValidation Tests")
struct CostValidationTests {

    // MARK: - Filter Input Tests

    @Test("Allows numeric characters")
    func allowsNumericCharacters() {
        #expect(CostValidation.filterCostInput("12345") == "12345")
    }

    @Test("Allows single decimal point")
    func allowsSingleDecimalPoint() {
        #expect(CostValidation.filterCostInput("12.50") == "12.50")
    }

    @Test("Strips non-numeric characters")
    func stripsNonNumericCharacters() {
        #expect(CostValidation.filterCostInput("$12.50") == "12.50")
        #expect(CostValidation.filterCostInput("abc") == "")
        #expect(CostValidation.filterCostInput("12abc34") == "1234")
    }

    @Test("Strips multiple decimal points")
    func stripsMultipleDecimalPoints() {
        #expect(CostValidation.filterCostInput("12.50.25") == "12.50")
    }

    @Test("Limits to 2 decimal places")
    func limitsToTwoDecimalPlaces() {
        #expect(CostValidation.filterCostInput("12.999") == "12.99")
        #expect(CostValidation.filterCostInput("0.123") == "0.12")
    }

    @Test("Handles empty input")
    func handlesEmptyInput() {
        #expect(CostValidation.filterCostInput("") == "")
    }

    @Test("Handles dollar sign prefix")
    func handlesDollarSignPrefix() {
        #expect(CostValidation.filterCostInput("$50") == "50")
    }

    @Test("Handles negative sign")
    func handlesNegativeSign() {
        #expect(CostValidation.filterCostInput("-50") == "50")
    }

    // MARK: - Validate Tests

    @Test("Valid cost returns nil")
    func validCostReturnsNil() {
        #expect(CostValidation.validate("12.50") == nil)
        #expect(CostValidation.validate("100") == nil)
        #expect(CostValidation.validate("0") == nil)
    }

    @Test("Empty cost returns nil")
    func emptyCostReturnsNil() {
        #expect(CostValidation.validate("") == nil)
    }

    @Test("Invalid cost returns error message")
    func invalidCostReturnsError() {
        #expect(CostValidation.validate("abc") != nil)
        #expect(CostValidation.validate("..") != nil)
    }
}
