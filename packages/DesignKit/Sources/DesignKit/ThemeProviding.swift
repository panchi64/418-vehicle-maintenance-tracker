import SwiftUI

/// Contract every app must satisfy to drive DesignKit's tokens.
/// Checkpoint's ThemeManager conforms with full theme-switching + IAP behavior;
/// Biombo ships a single static conformer that renders the AESTHETIC.md palette.
public protocol ThemeProviding: AnyObject, Observable {
    var backgroundPrimary: Color { get }
    var backgroundElevated: Color { get }
    var backgroundSubtle: Color { get }
    var surfaceInstrument: Color { get }
    var glow: Color { get }
    var gridLine: Color { get }

    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }

    var borderSubtle: Color { get }

    var accent: Color { get }
    var accentMuted: Color { get }

    var statusOverdue: Color { get }
    var statusDueSoon: Color { get }
    var statusGood: Color { get }
    var statusNeutral: Color { get }

    var fontDesign: Font.Design { get }
    var colorScheme: ColorScheme? { get }
}
