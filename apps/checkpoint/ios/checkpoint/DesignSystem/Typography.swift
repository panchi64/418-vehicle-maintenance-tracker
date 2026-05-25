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

    @MainActor private static func brutalist(
        size: CGFloat,
        weight: Font.Weight,
        jetBrains: DesignKitFonts.Weight
    ) -> Font {
        let design = ThemeManager.shared.current.fontDesign.toSwiftUI()
        if design == .monospaced {
            return DesignKitFonts.jetBrainsMono(jetBrains, size: size)
        }
        return .system(size: size, weight: weight, design: design)
    }

    /// 56pt Light - Hero data displays
    @MainActor static var brutalistHero: Font {
        brutalist(size: 56, weight: .light, jetBrains: .light)
    }

    /// 32pt Medium - Primary headings
    @MainActor static var brutalistTitle: Font {
        brutalist(size: 32, weight: .medium, jetBrains: .medium)
    }

    /// 20pt Medium - Section titles, service names
    @MainActor static var brutalistHeading: Font {
        brutalist(size: 20, weight: .medium, jetBrains: .medium)
    }

    /// 15pt Regular - Body text
    @MainActor static var brutalistBody: Font {
        brutalist(size: 15, weight: .regular, jetBrains: .regular)
    }

    /// 13pt Regular - Secondary content
    @MainActor static var brutalistSecondary: Font {
        brutalist(size: 13, weight: .regular, jetBrains: .regular)
    }

    /// 11pt Medium - Labels, all caps
    @MainActor static var brutalistLabel: Font {
        brutalist(size: 11, weight: .medium, jetBrains: .medium)
    }

    /// 11pt Bold - Emphasized labels
    @MainActor static var brutalistLabelBold: Font {
        brutalist(size: 11, weight: .bold, jetBrains: .bold)
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

    func brutalistSecondaryStyle() -> some View {
        modifier(BrutalistSecondaryStyle())
    }

    func brutalistLabelStyle(color: Color = Theme.textTertiary) -> some View {
        modifier(BrutalistLabelStyle(color: color))
    }
}
