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

    // Computed Color accessors
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
