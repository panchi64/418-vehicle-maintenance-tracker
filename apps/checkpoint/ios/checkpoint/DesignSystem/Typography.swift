//
//  Typography.swift
//  checkpoint
//
//  Brutalist-Tech-Modernist typography system
//  Monospace-forward, terminal aesthetic, structural honesty
//

import SwiftUI
import DesignKit

extension Font {
    // MARK: - Brutalist Type Scale
    //
    // Monospaced themes use bundled JetBrains Mono (shared via DesignKit).
    // Rounded/serif/system themes fall back to SF + the matching design.

    //
    // Every step scales with Dynamic Type (AESTHETIC.md [REQUIREMENT]): the
    // brand size holds at the default text setting and follows `textStyle`'s
    // curve from there. SF themes use the text style itself, so they get
    // Apple's native sizes and scaling.

    @MainActor private static func brutalist(
        size: CGFloat,
        weight: Font.Weight,
        jetBrains: DesignKitFonts.Weight,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        let design = ThemeManager.shared.current.fontDesign.toSwiftUI()
        if design == .monospaced {
            let face = UIAccessibility.isBoldTextEnabled ? boldTextFace(for: jetBrains) : jetBrains
            return DesignKitFonts.jetBrainsMono(face, size: size, relativeTo: textStyle)
        }
        return .system(textStyle, design: design, weight: weight)
    }

    /// Settings › Accessibility › Bold Text. SF picks it up on its own; a
    /// bundled face doesn't, so JetBrains Mono steps to a heavier file —
    /// regular text to bold, as Bold Text moves SF regular to semibold.
    /// Read when a token is built, so a mid-session toggle lands on the next
    /// render of each view rather than instantly everywhere.
    private static func boldTextFace(for weight: DesignKitFonts.Weight) -> DesignKitFonts.Weight {
        switch weight {
        case .light: .medium
        case .regular, .medium, .bold: .bold
        }
    }

    /// 56pt Light - Hero data displays
    @MainActor static var brutalistHero: Font {
        brutalist(size: 56, weight: .light, jetBrains: .light, relativeTo: .largeTitle)
    }

    /// 32pt Medium - Primary headings
    @MainActor static var brutalistTitle: Font {
        brutalist(size: 32, weight: .medium, jetBrains: .medium, relativeTo: .title)
    }

    /// 20pt Medium - Section titles, service names
    @MainActor static var brutalistHeading: Font {
        brutalist(size: 20, weight: .medium, jetBrains: .medium, relativeTo: .title3)
    }

    /// 15pt Bold - Section titles (Title Case, untracked, textPrimary).
    ///
    /// Sits between Heading and the body step so a section's name out-ranks
    /// the field labels beneath it on size, weight, case, and color — the 11pt
    /// caps it replaced disappeared in the squint test and read as one more
    /// label (tools/sketchpad/PORT_NOTES.md).
    @MainActor static var brutalistSectionTitle: Font {
        brutalist(size: 15, weight: .bold, jetBrains: .bold, relativeTo: .headline)
    }

    /// 15pt Regular - Body text
    @MainActor static var brutalistBody: Font {
        brutalist(size: 15, weight: .regular, jetBrains: .regular, relativeTo: .body)
    }

    /// 15pt Medium - The *primary* datum in a section or form.
    ///
    /// Exists because the scale previously jumped straight from 15 Regular to
    /// 11 Medium, leaving color as the only way to mark one line as more
    /// important than another — and color is already spoken for by status
    /// semantics. Without this step, hierarchy in a readout or a form is not
    /// expressible. See `docs/SURFACE_DOCTRINE.md` (Part 1, "Visual hierarchy").
    @MainActor static var brutalistBodyEmphasis: Font {
        brutalist(size: 15, weight: .medium, jetBrains: .medium, relativeTo: .body)
    }

    /// 13pt Regular - Secondary content
    @MainActor static var brutalistSecondary: Font {
        brutalist(size: 13, weight: .regular, jetBrains: .regular, relativeTo: .footnote)
    }

    /// 11pt Medium - Labels, all caps
    @MainActor static var brutalistLabel: Font {
        brutalist(size: 11, weight: .medium, jetBrains: .medium, relativeTo: .caption2)
    }

    /// 11pt Bold - Emphasized labels
    @MainActor static var brutalistLabelBold: Font {
        brutalist(size: 11, weight: .bold, jetBrains: .bold, relativeTo: .caption2)
    }
}

// MARK: - Brutalist Text Style Modifiers

struct BrutalistHeroStyle: ViewModifier {
    var color: Color = Theme.textPrimary

    func body(content: Content) -> some View {
        content
            .font(.brutalistHero)
            .foregroundStyle(color)
    }
}

struct BrutalistTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistTitle)
            .foregroundStyle(Theme.textPrimary)
            .textCase(.uppercase)
    }
}

struct BrutalistHeadingStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistHeading)
            .foregroundStyle(Theme.textPrimary)
    }
}

struct BrutalistBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistBody)
            .foregroundStyle(Theme.textPrimary)
    }
}

/// The one primary element of a section or form. Uses weight rather than color
/// so it composes with status tinting instead of competing with it.
struct BrutalistBodyEmphasisStyle: ViewModifier {
    var color: Color = Theme.textPrimary

    func body(content: Content) -> some View {
        content
            .font(.brutalistBodyEmphasis)
            .foregroundStyle(color)
    }
}

struct BrutalistSecondaryStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistSecondary)
            .foregroundStyle(Theme.textSecondary)
    }
}

struct BrutalistLabelStyle: ViewModifier {
    var color: Color = Theme.textTertiary

    func body(content: Content) -> some View {
        content
            .font(.brutalistLabel)
            .foregroundStyle(color)
            .textCase(.uppercase)
            .tracking(1.5)
    }
}

extension View {
    // MARK: - Brutalist Styles

    func brutalistHeroStyle(color: Color = Theme.textPrimary) -> some View {
        modifier(BrutalistHeroStyle(color: color))
    }

    func brutalistTitleStyle() -> some View {
        modifier(BrutalistTitleStyle())
    }

    func brutalistHeadingStyle() -> some View {
        modifier(BrutalistHeadingStyle())
    }

    func brutalistBodyStyle() -> some View {
        modifier(BrutalistBodyStyle())
    }

    func brutalistBodyEmphasisStyle(color: Color = Theme.textPrimary) -> some View {
        modifier(BrutalistBodyEmphasisStyle(color: color))
    }

    func brutalistSecondaryStyle() -> some View {
        modifier(BrutalistSecondaryStyle())
    }

    func brutalistLabelStyle(color: Color = Theme.textTertiary) -> some View {
        modifier(BrutalistLabelStyle(color: color))
    }
}
