import XCTest
@testable import Biombo

final class FuelOCRServiceTests: XCTestCase {
    func testParsePricesRecognizesDollarFormat() {
        let text = "REG $0.98 PREM $1.12 DSL $1.05"
        let candidates = FuelOCRService.parsePrices(from: text, confidence: 0.9)
        let values = candidates.map(\.value).sorted()
        XCTAssertEqual(values, [0.98, 1.05, 1.12])
    }

    func testParsePricesHandlesCommaDecimalSeparator() {
        let text = "1,23"
        let candidates = FuelOCRService.parsePrices(from: text, confidence: 0.8)
        XCTAssertEqual(candidates.first?.value, 1.23)
    }

    func testParsePricesFiltersOutOfRangeValues() {
        let text = "999.99 gallons sold today"
        let candidates = FuelOCRService.parsePrices(from: text, confidence: 0.5)
        XCTAssertTrue(candidates.isEmpty)
    }

    func testParsePricesReturnsEmptyForNoMatches() {
        let candidates = FuelOCRService.parsePrices(from: "no prices here", confidence: 1.0)
        XCTAssertTrue(candidates.isEmpty)
    }
}
