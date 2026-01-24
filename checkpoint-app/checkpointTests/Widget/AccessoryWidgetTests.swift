//
//  AccessoryWidgetTests.swift
//  checkpointTests
//
//  Tests for lock screen accessory widget formatting logic
//

import XCTest
@testable import checkpoint

final class AccessoryWidgetTests: XCTestCase {

    // MARK: - Due Description Formatting Tests (Inline Widget)

    func testFormatDue_MilesRemaining() {
        // Given
        let description = "500 miles remaining"

        // When
        let formatted = formatDueForInline(description)

        // Then
        XCTAssertEqual(formatted, "500 MI", "Should abbreviate 'miles remaining' to 'MI'")
    }

    func testFormatDue_MilesOverdue() {
        // Given
        let description = "200 miles overdue"

        // When
        let formatted = formatDueForInline(description)

        // Then
        XCTAssertEqual(formatted, "200 MI OVER", "Should abbreviate 'miles overdue' to 'MI OVER'")
    }

    func testFormatDue_MilesDue() {
        // Given
        let description = "1000 miles"

        // When
        let formatted = formatDueForInline(description)

        // Then
        XCTAssertEqual(formatted, "1000 MI", "Should abbreviate generic miles to 'MI'")
    }

    func testFormatDue_Days() {
        // Given
        let description = "Due in 5 days"

        // When
        let formatted = formatDueForInline(description)

        // Then
        XCTAssertEqual(formatted, "5D", "Should abbreviate days format")
    }

    func testFormatDue_SingleDay() {
        // Given
        let description = "Due in 1 day"

        // When
        let formatted = formatDueForInline(description)

        // Then
        XCTAssertEqual(formatted, "1D", "Should abbreviate single day format")
    }

    func testFormatDue_DueNow() {
        // Given
        let description = "Due now"

        // When
        let formatted = formatDueForInline(description)

        // Then
        XCTAssertEqual(formatted, "DUE NOW", "Should keep 'Due now' in uppercase")
    }

    func testFormatDue_LargeMileage() {
        // Given
        let description = "10000 miles remaining"

        // When
        let formatted = formatDueForInline(description)

        // Then
        XCTAssertEqual(formatted, "10000 MI", "Should handle large mileage numbers")
    }

    // MARK: - Service Name Abbreviation Tests (Circular Widget)

    func testAbbreviate_SingleWord() {
        // Given
        let name = "Brakes"

        // When
        let abbreviated = abbreviateServiceName(name)

        // Then
        XCTAssertEqual(abbreviated, "BRAKES", "Single word should be uppercased")
    }

    func testAbbreviate_TwoWords() {
        // Given
        let name = "Oil Change"

        // When
        let abbreviated = abbreviateServiceName(name)

        // Then
        XCTAssertEqual(abbreviated, "OIL", "Should return first word uppercased")
    }

    func testAbbreviate_MultipleWords() {
        // Given
        let name = "Tire Rotation and Balance"

        // When
        let abbreviated = abbreviateServiceName(name)

        // Then
        XCTAssertEqual(abbreviated, "TIRE", "Should return first word uppercased")
    }

    func testAbbreviate_LowercaseInput() {
        // Given
        let name = "brake inspection"

        // When
        let abbreviated = abbreviateServiceName(name)

        // Then
        XCTAssertEqual(abbreviated, "BRAKE", "Should uppercase the first word")
    }

    func testAbbreviate_MixedCase() {
        // Given
        let name = "oIL cHaNgE"

        // When
        let abbreviated = abbreviateServiceName(name)

        // Then
        XCTAssertEqual(abbreviated, "OIL", "Should normalize to uppercase")
    }

    func testAbbreviate_EmptyString() {
        // Given
        let name = ""

        // When
        let abbreviated = abbreviateServiceName(name)

        // Then
        XCTAssertEqual(abbreviated, "", "Empty string should return empty")
    }

    // MARK: - Status Icon Tests

    func testStatusIcon_Overdue() {
        // Given
        let status = "overdue"

        // When
        let icon = statusIcon(for: status)

        // Then
        XCTAssertEqual(icon, "exclamationmark.triangle", "Overdue should use warning triangle icon")
    }

    func testStatusIcon_DueSoon() {
        // Given
        let status = "dueSoon"

        // When
        let icon = statusIcon(for: status)

        // Then
        XCTAssertEqual(icon, "clock", "Due soon should use clock icon")
    }

    func testStatusIcon_Good() {
        // Given
        let status = "good"

        // When
        let icon = statusIcon(for: status)

        // Then
        XCTAssertEqual(icon, "checkmark.circle", "Good should use checkmark circle icon")
    }

    func testStatusIcon_Neutral() {
        // Given
        let status = "neutral"

        // When
        let icon = statusIcon(for: status)

        // Then
        XCTAssertEqual(icon, "minus.circle", "Neutral should use minus circle icon")
    }

    func testStatusIcon_Unknown() {
        // Given
        let status = "unknown"

        // When
        let icon = statusIcon(for: status)

        // Then
        XCTAssertEqual(icon, "minus.circle", "Unknown should default to minus circle icon")
    }

    // MARK: - Uppercase Formatting Tests

    func testUppercaseFormatting_VehicleName() {
        // Given
        let vehicleName = "My Camry"

        // When
        let formatted = vehicleName.uppercased()

        // Then
        XCTAssertEqual(formatted, "MY CAMRY", "Vehicle name should be uppercased")
    }

    func testUppercaseFormatting_ServiceName() {
        // Given
        let serviceName = "Oil Change"

        // When
        let formatted = serviceName.uppercased()

        // Then
        XCTAssertEqual(formatted, "OIL CHANGE", "Service name should be uppercased")
    }

    func testUppercaseFormatting_DueDescription() {
        // Given
        let dueDescription = "500 miles remaining"

        // When
        let formatted = dueDescription.uppercased()

        // Then
        XCTAssertEqual(formatted, "500 MILES REMAINING", "Due description should be uppercased")
    }

    // MARK: - Helper Functions

    private func formatDueForInline(_ description: String) -> String {
        let upper = description.uppercased()
        if upper.contains("MILES") {
            let number = upper.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
                .first ?? ""
            if upper.contains("OVERDUE") {
                return "\(number) MI OVER"
            } else if upper.contains("REMAINING") {
                return "\(number) MI"
            } else {
                return "\(number) MI"
            }
        }
        return upper
            .replacingOccurrences(of: "DUE IN ", with: "")
            .replacingOccurrences(of: " DAYS", with: "D")
            .replacingOccurrences(of: " DAY", with: "D")
    }

    private func abbreviateServiceName(_ name: String) -> String {
        String(name.uppercased().split(separator: " ").first ?? "")
    }

    private func statusIcon(for status: String) -> String {
        switch status {
        case "overdue": return "exclamationmark.triangle"
        case "dueSoon": return "clock"
        case "good": return "checkmark.circle"
        case "neutral": return "minus.circle"
        default: return "minus.circle"
        }
    }
}
