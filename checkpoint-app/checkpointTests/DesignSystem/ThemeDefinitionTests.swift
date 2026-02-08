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
        XCTAssertEqual(defaultTheme?.colorScheme, .dark)
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

    func testEquatable() {
        let theme1 = ThemeDefinition(
            id: "test", displayName: "Test", description: "Test theme",
            tier: .free, fontDesign: .monospaced, colorScheme: .dark,
            previewColors: ["#000000"],
            backgroundPrimary: "#000000", backgroundElevated: "#111111",
            backgroundSubtle: "#0A0A0A", surfaceInstrument: "#111111",
            glow: "#000000", gridLine: "#333333",
            textPrimary: "#FFFFFF", textSecondary: "#CCCCCC",
            textTertiary: "#999999", borderSubtle: "#333333",
            accent: "#FF0000", accentMuted: "#FF000080",
            statusOverdue: "#FF0000", statusDueSoon: "#FFAA00",
            statusGood: "#00FF00", statusNeutral: "#888888"
        )
        let theme2 = theme1
        XCTAssertEqual(theme1, theme2)
    }
}
