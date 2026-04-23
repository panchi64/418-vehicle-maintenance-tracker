/// DesignKit — shared SwiftPM design system for 418 Studio apps.
///
/// Phase 0 state: skeleton. The full Checkpoint DesignSystem extraction into
/// this package happens when Xcode is available for build verification (touches
/// ~1,750 existing call sites). Until then, this package ships:
///
/// - `ThemeProviding` protocol (contract)
/// - `ThemeEnvironment` injection hooks
/// - `AestheticBrutalistTheme` (Biombo provider, matches docs/AESTHETIC.md)
/// - `Spacing` tokens mirroring Checkpoint's current values
/// - `Color(hex:)` utility
///
/// See `packages/DesignKit/CLAUDE.md` for extraction plan and call-site strategy.
public enum DesignKit {
    public static let version = "0.1.0-phase0-scaffold"
}
