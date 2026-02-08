//
//  Typography.swift
//  checkpoint
//
//  Brutalist-Tech-Modernist typography system
//  Monospace-forward, terminal aesthetic, structural honesty
//

import SwiftUI

extension Font {
    // MARK: - Brutalist Monospace Type Scale

    /// 56pt Light - Hero data displays
    @MainActor static var brutalistHero: Font {
        .system(size: 56, weight: .light, design: ThemeManager.shared.current.fontDesign.toSwiftUI())
    }

    /// 32pt Medium - Primary headings
    @MainActor static var brutalistTitle: Font {
        .system(size: 32, weight: .medium, design: ThemeManager.shared.current.fontDesign.toSwiftUI())
    }

    /// 20pt Medium - Section titles, service names
    @MainActor static var brutalistHeading: Font {
        .system(size: 20, weight: .medium, design: ThemeManager.shared.current.fontDesign.toSwiftUI())
    }

    /// 15pt Regular - Body text
    @MainActor static var brutalistBody: Font {
        .system(size: 15, weight: .regular, design: ThemeManager.shared.current.fontDesign.toSwiftUI())
    }

    /// 13pt Regular - Secondary content
    @MainActor static var brutalistSecondary: Font {
        .system(size: 13, weight: .regular, design: ThemeManager.shared.current.fontDesign.toSwiftUI())
    }

    /// 11pt Medium - Labels, all caps
    @MainActor static var brutalistLabel: Font {
        .system(size: 11, weight: .medium, design: ThemeManager.shared.current.fontDesign.toSwiftUI())
    }

    /// 11pt Bold - Emphasized labels
    @MainActor static var brutalistLabelBold: Font {
        .system(size: 11, weight: .bold, design: ThemeManager.shared.current.fontDesign.toSwiftUI())
    }

    // MARK: - Legacy Aliases (for compatibility)

    @MainActor static var instrumentLarge: Font { brutalistHero }
    @MainActor static var instrumentMedium: Font { brutalistTitle }
    @MainActor static var instrumentLabel: Font { brutalistLabel }
    @MainActor static var instrumentSection: Font { brutalistLabel }
    @MainActor static var instrumentBody: Font { brutalistBody }
    @MainActor static var instrumentMono: Font { brutalistSecondary }

    @MainActor static var displayLarge: Font { brutalistHero }
    @MainActor static var headlineLarge: Font { brutalistTitle }
    @MainActor static var headline: Font { brutalistHeading }
    @MainActor static var title: Font { brutalistHeading }
    @MainActor static var bodyText: Font { brutalistBody }
    @MainActor static var bodySecondary: Font { brutalistSecondary }
    @MainActor static var caption: Font { brutalistSecondary }
    @MainActor static var captionSmall: Font { brutalistLabel }
    @MainActor static var monoLarge: Font { brutalistHero }
    @MainActor static var monoBody: Font { brutalistBody }
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

// MARK: - Legacy Style Modifiers (for compatibility)

struct InstrumentLargeStyle: ViewModifier {
    var color: Color = Theme.textPrimary

    func body(content: Content) -> some View {
        content
            .font(.brutalistHero)
            .foregroundStyle(color)
    }
}

struct InstrumentMediumStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistTitle)
            .foregroundStyle(Theme.textPrimary)
            .textCase(.uppercase)
    }
}

struct InstrumentLabelStyle: ViewModifier {
    var color: Color = Theme.textTertiary

    func body(content: Content) -> some View {
        content
            .font(.brutalistLabel)
            .foregroundStyle(color)
            .textCase(.uppercase)
            .tracking(1.5)
    }
}

struct InstrumentSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textSecondary)
            .textCase(.uppercase)
            .tracking(2)
    }
}

struct HeadlineLargeStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistTitle)
            .foregroundStyle(Theme.textPrimary)
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistHeading)
            .foregroundStyle(Theme.textPrimary)
    }
}

struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistHeading)
            .foregroundStyle(Theme.textPrimary)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistBody)
            .foregroundStyle(Theme.textPrimary)
    }
}

struct BodySecondaryStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistSecondary)
            .foregroundStyle(Theme.textSecondary)
    }
}

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.brutalistSecondary)
            .foregroundStyle(Theme.textSecondary)
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

    // MARK: - Legacy Styles (for compatibility)

    func instrumentLargeStyle(color: Color = Theme.textPrimary) -> some View {
        modifier(InstrumentLargeStyle(color: color))
    }

    func instrumentMediumStyle() -> some View {
        modifier(InstrumentMediumStyle())
    }

    func instrumentLabelStyle(color: Color = Theme.textTertiary) -> some View {
        modifier(InstrumentLabelStyle(color: color))
    }

    func instrumentSectionStyle() -> some View {
        modifier(InstrumentSectionStyle())
    }

    func headlineLargeStyle() -> some View {
        modifier(HeadlineLargeStyle())
    }

    func headlineStyle() -> some View {
        modifier(HeadlineStyle())
    }

    func titleStyle() -> some View {
        modifier(TitleStyle())
    }

    func bodyStyle() -> some View {
        modifier(BodyStyle())
    }

    func bodySecondaryStyle() -> some View {
        modifier(BodySecondaryStyle())
    }

    func captionStyle() -> some View {
        modifier(CaptionStyle())
    }
}
