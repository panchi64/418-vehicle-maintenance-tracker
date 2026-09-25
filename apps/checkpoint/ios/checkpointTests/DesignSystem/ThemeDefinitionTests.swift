//
//  ThemeDefinitionTests.swift
//  checkpointTests
//

import XCTest
import SwiftUI
@testable import checkpoint

final class ThemeDefinitionTests: XCTestCase {

    func testDecodeThemesFromJSON() throws {
        let url = Bundle.main.url(forResource: "Themes", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let themes = try JSONDecoder().decode([ThemeDefinition].self, from: data)

        XCTAssertEqual(themes.count, 8)
    }

    func testDefaultThemeExists() throws {
        let url = Bundle.main.url(forResource: "Themes", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let themes = try JSONDecoder().decode([ThemeDefinition].self, from: data)

        let defaultTheme = themes.first(where: { $0.id == "default" })
        XCTAssertNotNil(defaultTheme)
        XCTAssertEqual(defaultTheme?.displayName, "Checkpoint")
        XCTAssertEqual(defaultTheme?.tier, .free)
        XCTAssertEqual(defaultTheme?.fontDesign, .monospaced)
    }

    /// AESTHETIC.md's identity pair, in both orders: cerulean ground with
    /// off-white ink in dark, off-white ground with cerulean ink in light.
    func testDefaultThemeInvertsAcrossAppearances() throws {
        let url = Bundle.main.url(forResource: "Themes", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let themes = try JSONDecoder().decode([ThemeDefinition].self, from: data)
        let colors = try XCTUnwrap(themes.first(where: { $0.id == "default" })).colors

        XCTAssertEqual(colors.hex(.backgroundPrimary, in: .dark), "#0033BE")
        XCTAssertEqual(colors.hex(.textPrimary, in: .dark), "#F5F0DC")
        XCTAssertEqual(colors.hex(.backgroundPrimary, in: .light), "#F5F0DC")
        XCTAssertEqual(colors.hex(.textPrimary, in: .light), "#0033BE")
    }

    func testHighContrastOverridesLayerOnTheirBaseAppearance() throws {
        let json = """
        {
            "light": \(Self.tokens(fill: "#FFFFFF")),
            "dark": \(Self.tokens(fill: "#000000")),
            "darkHighContrast": { "textPrimary": "#FFFFFF" }
        }
        """
        let colors = try JSONDecoder().decode(ThemeAppearances.self, from: Data(json.utf8))

        XCTAssertEqual(colors.hex(.textPrimary, in: .darkHighContrast), "#FFFFFF")
        XCTAssertEqual(colors.hex(.accent, in: .darkHighContrast), "#000000")
        // An absent high-contrast set falls back to its base entirely.
        XCTAssertEqual(colors.hex(.textPrimary, in: .lightHighContrast), "#FFFFFF")
    }

    func testIncompleteBaseAppearanceFailsToDecode() {
        let json = """
        { "light": { "textPrimary": "#000000" }, "dark": \(Self.tokens(fill: "#000000")) }
        """
        XCTAssertThrowsError(try JSONDecoder().decode(ThemeAppearances.self, from: Data(json.utf8)))
    }

    func testUnknownTokenFailsToDecode() {
        let json = """
        {
            "light": \(Self.tokens(fill: "#FFFFFF")),
            "dark": \(Self.tokens(fill: "#000000")),
            "lightHighContrast": { "textPrimry": "#000000" }
        }
        """
        XCTAssertThrowsError(try JSONDecoder().decode(ThemeAppearances.self, from: Data(json.utf8)))
    }

    /// A complete color set with every token set to `fill`, as a JSON object.
    private static func tokens(fill: String) -> String {
        "{" + ThemeToken.allCases.map { "\"\($0.rawValue)\": \"\(fill)\"" }.joined(separator: ", ") + "}"
    }

    func testThemeTierDistribution() throws {
        let url = Bundle.main.url(forResource: "Themes", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let themes = try JSONDecoder().decode([ThemeDefinition].self, from: data)

        let free = themes.filter { $0.tier == .free }
        let pro = themes.filter { $0.tier == .pro }
        let rare = themes.filter { $0.tier == .rare }

        XCTAssertEqual(free.count, 1)
        XCTAssertEqual(pro.count, 4)
        XCTAssertEqual(rare.count, 3)
    }

    func testPreviewColorsNotEmpty() throws {
        let url = Bundle.main.url(forResource: "Themes", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let themes = try JSONDecoder().decode([ThemeDefinition].self, from: data)

        for theme in themes {
            XCTAssertFalse(theme.previewColors.isEmpty, "\(theme.id) has no preview colors")
            XCTAssertGreaterThanOrEqual(theme.previewColors.count, 3, "\(theme.id) should have at least 3 preview colors")
        }
    }

    func testEquatable() throws {
        let url = Bundle.main.url(forResource: "Themes", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let themes = try JSONDecoder().decode([ThemeDefinition].self, from: data)
        let again = try JSONDecoder().decode([ThemeDefinition].self, from: data)

        XCTAssertEqual(themes, again)
        XCTAssertNotEqual(themes[0], themes[1])
    }
}
