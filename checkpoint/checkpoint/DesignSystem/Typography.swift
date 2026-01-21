//
//  Typography.swift
//  checkpoint
//
//  Design system typography using SF Pro (system font)
//

import SwiftUI

extension Font {
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
