import XCTest
@testable import DesignKit

final class ThemeProvidingTests: XCTestCase {
    func testAestheticBrutalistThemeExposesAESTHETICPalette() {
        let theme = AestheticBrutalistTheme()
        XCTAssertEqual(theme.fontDesign, .monospaced)
        XCTAssertEqual(theme.colorScheme, .dark)
    }

    func testSpacingTokensMatchCheckpoint() {
        XCTAssertEqual(DKSpacing.xs, 4)
        XCTAssertEqual(DKSpacing.sm, 8)
        XCTAssertEqual(DKSpacing.md, 16)
        XCTAssertEqual(DKSpacing.lg, 24)
        XCTAssertEqual(DKSpacing.xl, 32)
        XCTAssertEqual(DKSpacing.xxl, 48)
        XCTAssertEqual(DKSpacing.tabBarOffset, 56)
    }
}
