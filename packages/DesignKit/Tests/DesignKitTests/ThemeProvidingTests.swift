import XCTest
@testable import DesignKit

final class ThemeProvidingTests: XCTestCase {
    func testAestheticBrutalistThemeExposesAESTHETICPalette() {
        let theme = AestheticBrutalistTheme()
        XCTAssertEqual(theme.fontDesign, .monospaced)
        XCTAssertEqual(theme.colorScheme, .dark)
    }

    func testSpacingTokensMatchCheckpoint() {
        XCTAssertEqual(Spacing.xs, 4)
        XCTAssertEqual(Spacing.sm, 8)
        XCTAssertEqual(Spacing.md, 16)
        XCTAssertEqual(Spacing.lg, 24)
        XCTAssertEqual(Spacing.xl, 32)
        XCTAssertEqual(Spacing.xxl, 48)
        XCTAssertEqual(Spacing.tabBarOffset, 56)
    }
}
