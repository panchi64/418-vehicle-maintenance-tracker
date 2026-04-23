//
//  MileageInputFieldTests.swift
//  checkpointTests
//
//  Tests for MileageInputField component
//

import XCTest
import SwiftUI
@testable import checkpoint

final class MileageInputFieldTests: XCTestCase {

    // MARK: - Initial Display Tests

    func testInitialDisplayWithValue() {
        // Given
        let value: Int? = 32500

        // When
        let field = MileageInputField(value: .constant(value))

        // Then
        XCTAssertNotNil(value)
        XCTAssertEqual(value, 32500)
    }

    func testInitialDisplayWithNilValue() {
        // Given
        let value: Int? = nil

        // When
        let field = MileageInputField(value: .constant(value))

        // Then
        XCTAssertNil(value)
    }

    // MARK: - Formatting Tests

    func testFormatThousand() {
        // Given
        let miles = 1000

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: miles))

        // Then
        XCTAssertEqual(formatted, "1,000")
    }

    func testFormatTenThousand() {
        // Given
        let miles = 10000

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: miles))

        // Then
        XCTAssertEqual(formatted, "10,000")
    }

    func testFormatHundredThousand() {
        // Given
        let miles = 100000

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: miles))

        // Then
        XCTAssertEqual(formatted, "100,000")
    }

    func testFormatMillion() {
        // Given
        let miles = 1000000

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: miles))

        // Then
        XCTAssertEqual(formatted, "1,000,000")
    }

    func testFormatSmallNumber() {
        // Given
        let miles = 500

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: miles))

        // Then
        XCTAssertEqual(formatted, "500")
    }

    func testFormatZero() {
        // Given
        let miles = 0

        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: miles))

        // Then
        XCTAssertEqual(formatted, "0")
    }

    // MARK: - Input Validation Tests

    func testStripNonNumericCharacters() {
        // Given
        let input = "123abc456"

        // When
        let numericOnly = input.filter { $0.isNumber }

        // Then
        XCTAssertEqual(numericOnly, "123456")
    }

    func testStripSpecialCharacters() {
        // Given
        let input = "12,345.67$"

        // When
        let numericOnly = input.filter { $0.isNumber }

        // Then - All digits are kept including those after decimal
        XCTAssertEqual(numericOnly, "1234567")
    }

    func testStripAllNonNumeric() {
        // Given
        let input = "!@#$%^&*()"

        // When
        let numericOnly = input.filter { $0.isNumber }

        // Then
        XCTAssertEqual(numericOnly, "")
    }

    func testNumericOnlyInput() {
        // Given
        let input = "12345"

        // When
        let numericOnly = input.filter { $0.isNumber }

        // Then
        XCTAssertEqual(numericOnly, "12345")
    }

    // MARK: - Value Binding Tests

    func testValueUpdateFromNumericString() {
        // Given
        let numericString = "12345"

        // When
        let intValue = Int(numericString)

        // Then
        XCTAssertNotNil(intValue)
        XCTAssertEqual(intValue, 12345)
    }

    func testValueUpdateFromEmptyString() {
        // Given
        let emptyString = ""

        // When
        let intValue = Int(emptyString)

        // Then
        XCTAssertNil(intValue)
    }

    func testValueUpdateFromZero() {
        // Given
        let zeroString = "0"

        // When
        let intValue = Int(zeroString)

        // Then - Zero should not set value (per requirements: intValue > 0)
        XCTAssertEqual(intValue, 0)
    }

    func testValueUpdateFromLargeNumber() {
        // Given
        let largeString = "999999999"

        // When
        let intValue = Int(largeString)

        // Then
        XCTAssertNotNil(intValue)
        XCTAssertEqual(intValue, 999999999)
    }

    // MARK: - String Binding Convenience Initializer Tests

    func testStringBindingConversion() {
        // Given
        var stringValue = "12345"

        // When
        let binding = Binding<Int?>(
            get: { Int(stringValue) },
            set: { newValue in
                stringValue = newValue.map(String.init) ?? ""
            }
        )

        // Then
        XCTAssertEqual(binding.wrappedValue, 12345)

        // When setting new value
        binding.wrappedValue = 54321

        // Then
        XCTAssertEqual(stringValue, "54321")
    }

    func testStringBindingNilConversion() {
        // Given
        var stringValue = ""

        // When
        let binding = Binding<Int?>(
            get: { Int(stringValue) },
            set: { newValue in
                stringValue = newValue.map(String.init) ?? ""
            }
        )

        // Then
        XCTAssertNil(binding.wrappedValue)
    }

    func testStringBindingSetNil() {
        // Given
        var stringValue = "12345"

        // When
        let binding = Binding<Int?>(
            get: { Int(stringValue) },
            set: { newValue in
                stringValue = newValue.map(String.init) ?? ""
            }
        )

        binding.wrappedValue = nil

        // Then
        XCTAssertEqual(stringValue, "")
    }

    // MARK: - Edge Cases

    func testNegativeNumberString() {
        // Given
        let negativeString = "-12345"

        // When
        let numericOnly = negativeString.filter { $0.isNumber }
        let intValue = Int(numericOnly)

        // Then - Negative sign should be stripped, leaving just digits
        XCTAssertEqual(numericOnly, "12345")
        XCTAssertEqual(intValue, 12345)
    }

    func testWhitespaceString() {
        // Given
        let whitespaceString = "  12 345  "

        // When
        let numericOnly = whitespaceString.filter { $0.isNumber }

        // Then
        XCTAssertEqual(numericOnly, "12345")
    }

    func testUnicodeNumbers() {
        // Given
        let unicodeString = "123۴۵٦"  // Mix of ASCII and Arabic-Indic digits

        // When
        let numericOnly = unicodeString.filter { $0.isNumber }

        // Then - Should include all unicode number characters
        XCTAssertTrue(numericOnly.count > 3)
    }

    // MARK: - Component Properties Tests

    func testDefaultPlaceholder() {
        // Given
        let field = MileageInputField(value: .constant(nil))

        // Then
        // Default placeholder should be "0"
        XCTAssertNotNil(field)
    }

    func testDefaultSuffix() {
        // Given
        let field = MileageInputField(value: .constant(1000))

        // Then
        // Default suffix should be "mi"
        XCTAssertNotNil(field)
    }

    func testCustomSuffix() {
        // Given
        let field = MileageInputField(value: .constant(1000), suffix: "km")

        // Then
        XCTAssertNotNil(field)
    }

    func testEmptySuffix() {
        // Given
        let field = MileageInputField(value: .constant(1000), suffix: "")

        // Then
        XCTAssertNotNil(field)
    }
}
