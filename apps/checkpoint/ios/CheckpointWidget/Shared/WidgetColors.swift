//
//  WidgetColors.swift
//  CheckpointWidget
//
//  Color and typography definitions for the widget extension
//  Brutalist-Tech-Modernist aesthetic
//

import SwiftUI

enum WidgetColors {
    // MARK: - Background (Cerulean blue to match app)
    static let backgroundPrimary = Color(red: 0.0, green: 0.2, blue: 0.745)
    static let gridLine = Color.white.opacity(0.15)

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.85)
    static let textTertiary = Color(white: 0.72)

    // MARK: - Status
    static let statusOverdue = Color(red: 0.92, green: 0.34, blue: 0.34)
    static let statusDueSoon = Color(red: 0.95, green: 0.77, blue: 0.25)
    static let statusGood = Color(red: 0.34, green: 0.78, blue: 0.47)
    static let statusNeutral = Color(white: 0.5)

    // MARK: - Brutalist Constants
    static let borderWidth: CGFloat = 2
}

// MARK: - Widget Typography
//
// Every face is a text style so the widget follows Dynamic Type. Only the hero
// numeral uses a point size, and that one scales relative to `.largeTitle`
// (see `WidgetNumeral`).

extension Font {
    /// Footnote mono — body text, list rows
    static var widgetBody: Font {
        .system(.footnote, design: .monospaced)
    }

    /// Caption 2 mono medium — uppercase labels, units, status words
    static var widgetLabel: Font {
        .system(.caption2, design: .monospaced).weight(.medium)
    }

    /// Subheadline mono semibold — headlines (service / vehicle name)
    static var widgetHeadline: Font {
        .system(.subheadline, design: .monospaced).weight(.semibold)
    }
}

/// The hero figure of a widget: bold mono at `size`, scaled with Dynamic Type
/// relative to `.largeTitle`, shrinking to fit rather than truncating.
struct WidgetNumeral: View {
    let text: String
    @ScaledMetric private var size: CGFloat

    init(_ text: String, size: CGFloat) {
        self.text = text
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}
