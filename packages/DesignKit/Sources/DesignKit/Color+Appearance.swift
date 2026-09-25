import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The four appearances every themed color has to answer for: the system
/// light/dark setting, each with and without Settings > Accessibility >
/// Increase Contrast.
public enum ThemeAppearance: String, CaseIterable, Sendable {
    case light
    case dark
    case lightHighContrast
    case darkHighContrast

    public init(isDark: Bool, isHighContrast: Bool) {
        switch (isDark, isHighContrast) {
        case (false, false): self = .light
        case (true, false): self = .dark
        case (false, true): self = .lightHighContrast
        case (true, true): self = .darkHighContrast
        }
    }
}

public extension Color {
    /// A color that picks its value at render time from the environment's
    /// `colorScheme` and `colorSchemeContrast`, the same way an asset-catalog
    /// color does. Call sites keep writing `.foregroundStyle(token)`; the token
    /// itself answers for every appearance.
    ///
    /// Backed by a trait-resolving `UIColor` (iOS) / `NSColor` (macOS), so it
    /// also adapts when bridged into UIKit via `UIColor(_:)`. watchOS has no
    /// light appearance and no dynamic provider, so it takes `dark`.
    init(light: Color, dark: Color, lightHighContrast: Color, darkHighContrast: Color) {
        #if os(watchOS)
        self = dark
        #elseif canImport(UIKit)
        let resolved = (
            light: UIColor(light),
            dark: UIColor(dark),
            lightHighContrast: UIColor(lightHighContrast),
            darkHighContrast: UIColor(darkHighContrast)
        )
        self.init(uiColor: UIColor { traits in
            switch ThemeAppearance(
                isDark: traits.userInterfaceStyle == .dark,
                isHighContrast: traits.accessibilityContrast == .high
            ) {
            case .light: return resolved.light
            case .dark: return resolved.dark
            case .lightHighContrast: return resolved.lightHighContrast
            case .darkHighContrast: return resolved.darkHighContrast
            }
        })
        #elseif canImport(AppKit)
        let resolved = (
            light: NSColor(light),
            dark: NSColor(dark),
            lightHighContrast: NSColor(lightHighContrast),
            darkHighContrast: NSColor(darkHighContrast)
        )
        self.init(nsColor: NSColor(name: nil) { appearance in
            switch appearance.bestMatch(from: [
                .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
            ]) {
            case .darkAqua: return resolved.dark
            case .accessibilityHighContrastAqua: return resolved.lightHighContrast
            case .accessibilityHighContrastDarkAqua: return resolved.darkHighContrast
            default: return resolved.light
            }
        })
        #else
        self = dark
        #endif
    }
}
