//
//  WidgetColors.swift
//  CheckpointWidget
//
//  Color and typography definitions for the widget extension
//  Brutalist-Tech-Modernist aesthetic
//

import SwiftUI

enum WidgetColors {
    // MARK: - Backgrounds (Cerulean blue to match app)
    static let backgroundPrimary = Color(red: 0.0, green: 0.2, blue: 0.745)
    static let backgroundElevated = Color(red: 0.08, green: 0.28, blue: 0.82)
    static let gridLine = Color.white.opacity(0.15)

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.85)
    static let textTertiary = Color(white: 0.6)

    // MARK: - Accent
    static let accent = Color(red: 0.91, green: 0.608, blue: 0.235) // #E89B3C

    // MARK: - Status
    static let statusOverdue = Color(red: 0.92, green: 0.34, blue: 0.34)
    static let statusDueSoon = Color(red: 0.95, green: 0.77, blue: 0.25)
    static let statusGood = Color(red: 0.34, green: 0.78, blue: 0.47)
    static let statusNeutral = Color(white: 0.5)

    // MARK: - Brutalist Constants
    static let borderWidth: CGFloat = 2
}

// MARK: - Widget Brutalist Typography

extension Font {
    /// 13pt Mono Regular - Widget body text
    static var widgetBody: Font {
        .system(size: 13, weight: .regular, design: .monospaced)
    }

    /// 11pt Mono Medium - Widget labels
    static var widgetLabel: Font {
        .system(size: 11, weight: .medium, design: .monospaced)
    }

    /// 15pt Mono Medium - Widget headlines
    static var widgetHeadline: Font {
        .system(size: 15, weight: .medium, design: .monospaced)
    }

    /// 9pt Mono Regular - Widget caption
    static var widgetCaption: Font {
        .system(size: 9, weight: .regular, design: .monospaced)
    }
}
