//
//  WatchDesignTokens.swift
//  CheckpointWatch
//
//  Brutalist-Tech-Modernist design tokens adapted for Apple Watch
//  Monospace, ALL CAPS labels, zero radius, status colors
//

import SwiftUI

// MARK: - Watch Colors

enum WatchColors {
    // Status
    static let statusOverdue = Color.red
    static let statusDueSoon = Color.yellow
    static let statusGood = Color.green
    static let statusNeutral = Color.gray

    // Accent
    static let accent = Color(red: 0.91, green: 0.608, blue: 0.235) // #E89B3C

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textTertiary = Color(white: 0.45)

    // Surfaces
    static let backgroundPrimary = Color.black
    static let surfaceElevated = Color(white: 0.1)
    static let gridLine = Color.white.opacity(0.15)

    // Borders
    static let borderWidth: CGFloat = 2
}

// MARK: - Watch Typography

extension Font {
    /// 15pt Mono Medium — Watch headlines
    static var watchHeadline: Font {
        .system(size: 15, weight: .medium, design: .monospaced)
    }

    /// 13pt Mono Regular — Watch body
    static var watchBody: Font {
        .system(size: 13, weight: .regular, design: .monospaced)
    }

    /// 11pt Mono Medium — Watch labels
    static var watchLabel: Font {
        .system(size: 11, weight: .medium, design: .monospaced)
    }

    /// 9pt Mono Regular — Watch caption
    static var watchCaption: Font {
        .system(size: 9, weight: .regular, design: .monospaced)
    }

    /// 22pt Mono Bold — Watch large number display
    static var watchDisplayLarge: Font {
        .system(size: 22, weight: .bold, design: .monospaced)
    }

    /// 17pt Mono Semibold — Watch title
    static var watchTitle: Font {
        .system(size: 17, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Status Color Extension

extension WatchServiceStatus {
    var color: Color {
        switch self {
        case .overdue: return WatchColors.statusOverdue
        case .dueSoon: return WatchColors.statusDueSoon
        case .good: return WatchColors.statusGood
        case .neutral: return WatchColors.statusNeutral
        }
    }

    var icon: String {
        switch self {
        case .overdue: return "exclamationmark.triangle"
        case .dueSoon: return "clock"
        case .good: return "checkmark.circle"
        case .neutral: return "minus.circle"
        }
    }
}

// MARK: - Watch Spacing

enum WatchSpacing {
    static let xs: CGFloat = 2
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
}

// MARK: - Status Indicator (8x8pt square, zero radius)

struct StatusSquare: View {
    let status: WatchServiceStatus

    var body: some View {
        Rectangle()
            .fill(status.color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Watch Section Divider

struct WatchDivider: View {
    var body: some View {
        Rectangle()
            .fill(WatchColors.gridLine)
            .frame(height: WatchColors.borderWidth)
    }
}
