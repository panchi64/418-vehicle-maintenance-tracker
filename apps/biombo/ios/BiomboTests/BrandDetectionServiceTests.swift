import XCTest
@testable import Biombo

final class BrandDetectionServiceTests: XCTestCase {
    private let brands = ["Puma", "Shell", "Total", "Gulf", "Sol", "Texaco"]

    @MainActor
    func testMatchesCaseInsensitive() {
        let match = BrandDetectionService.detect(in: "PUMA GAS PREMIUM 1.12", knownBrands: brands)
        XCTAssertEqual(match?.brand, "Puma")
    }

    @MainActor
    func testMatchesMixedCase() {
        let match = BrandDetectionService.detect(in: "welcome to shell oeste", knownBrands: brands)
        XCTAssertEqual(match?.brand, "Shell")
    }

    @MainActor
    func testPrefersLongerBrand() {
        let match = BrandDetectionService.detect(
            in: "texaco star",
            knownBrands: ["Sol", "Texaco"]
        )
        XCTAssertEqual(match?.brand, "Texaco")
    }

    @MainActor
    func testReturnsNilWhenNoBrandFound() {
        let match = BrandDetectionService.detect(in: "lukoil 92", knownBrands: brands)
        XCTAssertNil(match)
    }
}
