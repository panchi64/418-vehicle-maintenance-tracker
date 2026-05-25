//
//  ThemeManager+DesignKit.swift
//  checkpoint
//
//  Bridges Checkpoint's ThemeManager to DesignKit's ThemeProviding contract so
//  Biombo (and any future app) can share DesignKit modifiers that read from an
//  environment-injected theme.
//

import SwiftUI
import DesignKit

extension ThemeManager: DesignKit.ThemeProviding {
    var backgroundPrimary: Color { current.backgroundPrimaryColor }
    var backgroundElevated: Color { current.backgroundElevatedColor }
    var backgroundSubtle: Color { current.backgroundSubtleColor }
    var surfaceInstrument: Color { current.surfaceInstrumentColor }
    var glow: Color { current.glowColor }
    var gridLine: Color { current.gridLineColor }

    var textPrimary: Color { current.textPrimaryColor }
    var textSecondary: Color { current.textSecondaryColor }
    var textTertiary: Color { current.textTertiaryColor }

    var borderSubtle: Color { current.borderSubtleColor }

    var accent: Color { current.accentColor }
    var accentMuted: Color { current.accentMutedColor }

    var statusOverdue: Color { current.statusOverdueColor }
    var statusDueSoon: Color { current.statusDueSoonColor }
    var statusGood: Color { current.statusGoodColor }
    var statusNeutral: Color { current.statusNeutralColor }

    var fontDesign: Font.Design { current.fontDesign.toSwiftUI() }
    var colorScheme: ColorScheme? {
        switch current.colorScheme {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}
