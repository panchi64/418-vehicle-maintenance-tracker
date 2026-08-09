//
//  ThemeDefinition.swift
//  checkpoint
//

import SwiftUI

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

// MARK: - Theme Color Scheme

enum ThemeColorScheme: String, Codable {
    case dark
    case light
    case system
}

// MARK: - Theme Tier

enum ThemeTier: String, Codable {
    case free
    case pro
    case rare
}

// MARK: - Theme Definition

struct ThemeDefinition: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let tier: ThemeTier
    let fontDesign: ThemeFontDesign
    let colorScheme: ThemeColorScheme
    let previewColors: [String]

    // 16 color hex strings matching Theme's color properties
    let backgroundPrimary: String
    let backgroundElevated: String
    let backgroundSubtle: String
    let surfaceInstrument: String
    let glow: String
    let gridLine: String
    let textPrimary: String
    let textSecondary: String
    let textTertiary: String
    let borderSubtle: String
    let accent: String
    let accentMuted: String
    let statusOverdue: String
    let statusDueSoon: String
    let statusGood: String
    let statusNeutral: String

    // Computed Color accessors.
    //
    // Each one parses a hex string through a `Scanner`, so they are *not* free
    // to read in a view body — a screenful of rows touches theme tokens
    // hundreds of times. `ThemePalette` resolves all sixteen once per theme
    // change; read colors through `Theme.*`, which goes to the palette.
    var backgroundPrimaryColor: Color { Color(hex: backgroundPrimary) }
    var backgroundElevatedColor: Color { Color(hex: backgroundElevated) }
    var backgroundSubtleColor: Color { Color(hex: backgroundSubtle) }
    var surfaceInstrumentColor: Color { Color(hex: surfaceInstrument) }
    var glowColor: Color { Color(hex: glow) }
    var gridLineColor: Color { Color(hex: gridLine) }
    var textPrimaryColor: Color { Color(hex: textPrimary) }
    var textSecondaryColor: Color { Color(hex: textSecondary) }
    var textTertiaryColor: Color { Color(hex: textTertiary) }
    var borderSubtleColor: Color { Color(hex: borderSubtle) }
    var accentColor: Color { Color(hex: accent) }
    var accentMutedColor: Color { Color(hex: accentMuted) }
    var statusOverdueColor: Color { Color(hex: statusOverdue) }
    var statusDueSoonColor: Color { Color(hex: statusDueSoon) }
    var statusGoodColor: Color { Color(hex: statusGood) }
    var statusNeutralColor: Color { Color(hex: statusNeutral) }
}

// MARK: - Resolved Palette

/// A theme's sixteen colors, parsed once.
///
/// `ThemeDefinition` stores hex *strings*, and turning one into a `Color` runs a
/// `Scanner` over it. Since every token in `Theme` resolves through the active
/// theme, a body that reads a dozen tokens per row was re-parsing the same
/// strings thousands of times per screen. `ThemeManager` holds one of these and
/// rebuilds it only when the active theme changes.
struct ThemePalette: Equatable {
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
        backgroundPrimary = theme.backgroundPrimaryColor
        backgroundElevated = theme.backgroundElevatedColor
        backgroundSubtle = theme.backgroundSubtleColor
        surfaceInstrument = theme.surfaceInstrumentColor
        glow = theme.glowColor
        gridLine = theme.gridLineColor
        textPrimary = theme.textPrimaryColor
        textSecondary = theme.textSecondaryColor
        textTertiary = theme.textTertiaryColor
        borderSubtle = theme.borderSubtleColor
        accent = theme.accentColor
        accentMuted = theme.accentMutedColor
        statusOverdue = theme.statusOverdueColor
        statusDueSoon = theme.statusDueSoonColor
        statusGood = theme.statusGoodColor
        statusNeutral = theme.statusNeutralColor
    }
}
