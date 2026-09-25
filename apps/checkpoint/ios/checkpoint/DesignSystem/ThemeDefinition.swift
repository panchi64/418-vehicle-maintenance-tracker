//
//  ThemeDefinition.swift
//  checkpoint
//

import SwiftUI
import DesignKit

// MARK: - Theme Font Design

enum ThemeFontDesign: String, Codable {
    case monospaced
    case rounded
    case serif
    case system

    func toSwiftUI() -> Font.Design {
        switch self {
        case .monospaced: return .monospaced
        case .rounded: return .rounded
        case .serif: return .serif
        case .system: return .default
        }
    }
}

// MARK: - Theme Tier

enum ThemeTier: String, Codable {
    case free
    case pro
    case rare
}

// MARK: - Color Tokens

/// The sixteen color tokens every theme defines, once per appearance. The raw
/// values are the JSON keys in `Themes.json`.
enum ThemeToken: String, CaseIterable, Sendable {
    case backgroundPrimary
    case backgroundElevated
    case backgroundSubtle
    case surfaceInstrument
    case glow
    case gridLine
    case textPrimary
    case textSecondary
    case textTertiary
    case borderSubtle
    case accent
    case accentMuted
    case statusOverdue
    case statusDueSoon
    case statusGood
    case statusNeutral
}

// MARK: - Appearances

/// A theme's hex strings for each `ThemeAppearance`, fully resolved.
///
/// In `Themes.json`, `light` and `dark` must each define all sixteen tokens.
/// `lightHighContrast` / `darkHighContrast` are **overrides** layered on their
/// base appearance, so they only list what Increase Contrast changes. Decoding
/// merges them, so every appearance here is complete.
struct ThemeAppearances: Decodable, Equatable {
    private let sets: [ThemeAppearance: [ThemeToken: String]]

    func hex(_ token: ThemeToken, in appearance: ThemeAppearance) -> String {
        // Decoding guarantees every appearance holds every token.
        sets[appearance]?[token] ?? "#FF00FF"
    }

    private struct Key: CodingKey {
        let stringValue: String
        init(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)

        func tokens(_ appearance: ThemeAppearance, required: Bool) throws -> [ThemeToken: String] {
            let key = Key(stringValue: appearance.rawValue)
            guard container.contains(key) else {
                if required {
                    throw DecodingError.keyNotFound(key, .init(
                        codingPath: container.codingPath,
                        debugDescription: "Every theme must define a complete '\(appearance.rawValue)' color set."
                    ))
                }
                return [:]
            }
            let raw = try container.decode([String: String].self, forKey: key)
            var result: [ThemeToken: String] = [:]
            for (name, hex) in raw {
                guard let token = ThemeToken(rawValue: name) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: key, in: container,
                        debugDescription: "Unknown color token '\(name)' in '\(appearance.rawValue)'."
                    )
                }
                result[token] = hex
            }
            if required, let missing = ThemeToken.allCases.first(where: { result[$0] == nil }) {
                throw DecodingError.dataCorruptedError(
                    forKey: key, in: container,
                    debugDescription: "'\(appearance.rawValue)' is missing '\(missing.rawValue)'."
                )
            }
            return result
        }

        let light = try tokens(.light, required: true)
        let dark = try tokens(.dark, required: true)
        sets = [
            .light: light,
            .dark: dark,
            .lightHighContrast: light.merging(try tokens(.lightHighContrast, required: false)) { $1 },
            .darkHighContrast: dark.merging(try tokens(.darkHighContrast, required: false)) { $1 },
        ]
    }
}

// MARK: - Theme Definition

struct ThemeDefinition: Identifiable, Decodable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let tier: ThemeTier
    let fontDesign: ThemeFontDesign
    /// Identity swatches for the picker. Appearance-independent on purpose:
    /// they show what the theme *is*, not how it renders right now.
    let previewColors: [String]
    let colors: ThemeAppearances
}

// MARK: - Resolved Palette

/// A theme's sixteen colors, parsed once, each adapting to the environment.
///
/// `ThemeDefinition` stores hex *strings*, and turning one into a `Color` runs a
/// `Scanner` over it. Since every token in `Theme` resolves through the active
/// theme, a body that reads a dozen tokens per row was re-parsing the same
/// strings thousands of times per screen. `ThemeManager` holds one of these and
/// rebuilds it only when the active theme changes.
///
/// Each color is a DesignKit adaptive color: it picks its light, dark, or
/// Increase Contrast value from `\.colorScheme` / `\.colorSchemeContrast` at
/// render time, so the app follows the system appearance with no call-site
/// changes and no palette rebuild when the appearance flips.
struct ThemePalette {
    let backgroundPrimary: Color
    let backgroundElevated: Color
    let backgroundSubtle: Color
    let surfaceInstrument: Color
    let glow: Color
    let gridLine: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let borderSubtle: Color
    let accent: Color
    let accentMuted: Color
    let statusOverdue: Color
    let statusDueSoon: Color
    let statusGood: Color
    let statusNeutral: Color

    init(_ theme: ThemeDefinition) {
        func color(_ token: ThemeToken) -> Color {
            let hex = { (appearance: ThemeAppearance) in
                Color(hex: theme.colors.hex(token, in: appearance))
            }
            return Color(
                light: hex(.light),
                dark: hex(.dark),
                lightHighContrast: hex(.lightHighContrast),
                darkHighContrast: hex(.darkHighContrast)
            )
        }
        backgroundPrimary = color(.backgroundPrimary)
        backgroundElevated = color(.backgroundElevated)
        backgroundSubtle = color(.backgroundSubtle)
        surfaceInstrument = color(.surfaceInstrument)
        glow = color(.glow)
        gridLine = color(.gridLine)
        textPrimary = color(.textPrimary)
        textSecondary = color(.textSecondary)
        textTertiary = color(.textTertiary)
        borderSubtle = color(.borderSubtle)
        accent = color(.accent)
        accentMuted = color(.accentMuted)
        statusOverdue = color(.statusOverdue)
        statusDueSoon = color(.statusDueSoon)
        statusGood = color(.statusGood)
        statusNeutral = color(.statusNeutral)
    }
}
