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

// Colors are served from the resolved `palette`, not re-parsed from `current`'s
// hex strings on each access — same reasoning as `Theme`'s tokens.
extension ThemeManager: DesignKit.ThemeProviding {
    var backgroundPrimary: Color { palette.backgroundPrimary }
    var backgroundElevated: Color { palette.backgroundElevated }
    var backgroundSubtle: Color { palette.backgroundSubtle }
    var surfaceInstrument: Color { palette.surfaceInstrument }
    var glow: Color { palette.glow }
    var gridLine: Color { palette.gridLine }

    var textPrimary: Color { palette.textPrimary }
    var textSecondary: Color { palette.textSecondary }
    var textTertiary: Color { palette.textTertiary }

    var borderSubtle: Color { palette.borderSubtle }

    var accent: Color { palette.accent }
    var accentMuted: Color { palette.accentMuted }

    var statusOverdue: Color { palette.statusOverdue }
    var statusDueSoon: Color { palette.statusDueSoon }
    var statusGood: Color { palette.statusGood }
    var statusNeutral: Color { palette.statusNeutral }

    var fontDesign: Font.Design { current.fontDesign.toSwiftUI() }
    // `colorScheme` takes the protocol default (nil): every theme defines
    // light, dark, and Increase Contrast palettes, so the app follows the
    // system appearance instead of forcing one per theme.
}
