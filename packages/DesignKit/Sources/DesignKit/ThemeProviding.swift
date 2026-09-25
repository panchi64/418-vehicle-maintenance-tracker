import SwiftUI

/// Contract every app must satisfy to drive DesignKit's tokens.
/// Checkpoint's ThemeManager conforms with full theme-switching + IAP behavior;
/// Biombo ships a single static conformer that renders the AESTHETIC.md palette.
///
/// **Color tokens resolve against the environment, not against the provider.**
/// A conformer that follows the system appearance returns adaptive colors —
/// `Color(light:dark:lightHighContrast:darkHighContrast:)` — so one token value
/// answers for `\.colorScheme` and `\.colorSchemeContrast` at render time and
/// call sites never branch on appearance themselves.
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
    /// An appearance the app forces with `.preferredColorScheme`. `nil` — the
    /// default — follows the system setting, which HIG expects; only a provider
    /// whose tokens exist in one appearance should return non-nil.
    var colorScheme: ColorScheme? { get }
}

public extension ThemeProviding {
    var colorScheme: ColorScheme? { nil }


    func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        if fontDesign == .monospaced {
            return DesignKitFonts.jetBrainsMono(.init(weight), textStyle: style)
        }
        return .system(style, design: fontDesign).weight(weight)
    }
}
