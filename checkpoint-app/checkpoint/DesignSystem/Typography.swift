//
//  Typography.swift
//  checkpoint
//
//  Design system typography using SF Pro (system font) and Barlow (instrument cluster)
//

import SwiftUI

// MARK: - Custom Font Names

private enum FontName {
    static let barlowLight = "Barlow-Light"
    static let barlowRegular = "Barlow-Regular"
    static let barlowSemiBold = "Barlow-SemiBold"
}

extension Font {
    // MARK: - Barlow Instrument Cluster Fonts

    /// 48pt Barlow Light - Hero numbers, large instrument displays
    static var instrumentLarge: Font {
        .custom(FontName.barlowLight, size: 48)
    }

    /// 28pt Barlow SemiBold - Service names, medium displays
    static var instrumentMedium: Font {
        .custom(FontName.barlowSemiBold, size: 28)
    }

    /// 11pt Barlow SemiBold - Labels, all caps with tracking
    static var instrumentLabel: Font {
        .custom(FontName.barlowSemiBold, size: 11)
    }

    /// 14pt Barlow SemiBold - Section headers
    static var instrumentSection: Font {
        .custom(FontName.barlowSemiBold, size: 14)
    }

    /// 17pt Barlow Regular - Body text in instrument style
    static var instrumentBody: Font {
        .custom(FontName.barlowRegular, size: 17)
    }

    /// Monospaced Barlow for mileage displays
    static var instrumentMono: Font {
        .custom(FontName.barlowLight, size: 15).monospacedDigit()
    }

    // MARK: - Type Scale (SF Pro - Apple's system font)

    /// 34pt Bold - Hero numbers, large displays
    static var displayLarge: Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }

    /// 28pt Semibold - Screen titles
    static var headlineLarge: Font {
        .system(size: 28, weight: .semibold, design: .default)
    }

    /// 22pt Semibold - Section headers, "Next Up" service name
    static var headline: Font {
        .system(size: 22, weight: .semibold, design: .default)
    }

    /// 17pt Semibold - Card titles, emphasis
    static var title: Font {
        .system(size: 17, weight: .semibold, design: .default)
    }

    /// 17pt Regular - Primary content
    static var bodyText: Font {
        .system(size: 17, weight: .regular, design: .default)
    }

    /// 15pt Regular - Supporting content
    static var bodySecondary: Font {
        .system(size: 15, weight: .regular, design: .default)
    }

    /// 13pt Medium - Labels, metadata
    static var caption: Font {
        .system(size: 13, weight: .medium, design: .default)
    }

    /// 11pt Medium - Timestamps, tertiary info
    static var captionSmall: Font {
        .system(size: 11, weight: .medium, design: .default)
    }

    /// Monospaced numbers for mileage displays
    static var monoLarge: Font {
        .system(size: 42, weight: .light, design: .monospaced)
    }

    /// Monospaced for inline numbers
    static var monoBody: Font {
        .system(size: 15, weight: .regular, design: .monospaced)
    }
}

// MARK: - Text Style Modifiers

// MARK: Instrument Cluster Styles

struct InstrumentLargeStyle: ViewModifier {
    var color: Color = Theme.textPrimary

    func body(content: Content) -> some View {
        content
            .font(.instrumentLarge)
            .foregroundStyle(color)
            .tracking(-1)
    }
}

struct InstrumentMediumStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.instrumentMedium)
            .foregroundStyle(Theme.textPrimary)
            .tracking(-0.5)
    }
}

struct InstrumentLabelStyle: ViewModifier {
    var color: Color = Theme.textTertiary

    func body(content: Content) -> some View {
        content
            .font(.instrumentLabel)
            .foregroundStyle(color)
            .textCase(.uppercase)
            .tracking(1.5)
    }
}

struct InstrumentSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.instrumentSection)
            .foregroundStyle(Theme.textSecondary)
            .textCase(.uppercase)
            .tracking(2)
    }
}

// MARK: SF Pro Styles

struct HeadlineLargeStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headlineLarge)
            .foregroundStyle(Theme.textPrimary)
            .tracking(-0.5)
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(Theme.textPrimary)
            .tracking(-0.3)
    }
}

struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .foregroundStyle(Theme.textPrimary)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.bodyText)
            .foregroundStyle(Theme.textPrimary)
    }
}

struct BodySecondaryStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.bodySecondary)
            .foregroundStyle(Theme.textSecondary)
    }
}

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
    }
}

extension View {
    // MARK: - Instrument Cluster Styles

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

    // MARK: - SF Pro Styles

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
