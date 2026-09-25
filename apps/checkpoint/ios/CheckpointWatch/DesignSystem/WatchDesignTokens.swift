//
//  WatchDesignTokens.swift
//  CheckpointWatch
//
//  Brutalist-Tech-Modernist design tokens adapted for Apple Watch
//  Monospace, ALL CAPS labels, zero radius, status as shape + word
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
    static let textSecondary = Color(white: 0.75)
    static let textTertiary = Color(white: 0.6)

    // Surfaces
    static let backgroundPrimary = Color.black
    static let gridLine = Color.white.opacity(0.15)

    // Borders
    static let borderWidth: CGFloat = 2
}

// MARK: - Watch Typography
//
// Every face is a text style so the app follows the watch's text size. Only the
// mileage readout uses a point size, scaled relative to `.title`
// (see `WatchNumeral`).

extension Font {
    /// Headline mono — vehicle name, confirmation words
    static var watchHeadline: Font {
        .system(.headline, design: .monospaced)
    }

    /// Body mono — primary values, button titles
    static var watchBody: Font {
        .system(.body, design: .monospaced)
    }

    /// Footnote mono medium — row titles, labels
    static var watchLabel: Font {
        .system(.footnote, design: .monospaced).weight(.medium)
    }

    /// Caption 2 mono — supporting text, status words
    static var watchCaption: Font {
        .system(.caption2, design: .monospaced)
    }

    /// Title 3 mono semibold — screen subject (service being completed)
    static var watchTitle: Font {
        .system(.title3, design: .monospaced).weight(.semibold)
    }
}

/// Large mono figure that scales with the text size relative to `.title`.
struct WatchNumeral: View {
    let text: String
    @ScaledMetric private var size: CGFloat

    init(_ text: String, size: CGFloat = 28) {
        self.text = text
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .title)
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .minimumScaleFactor(0.6)
            .lineLimit(1)
    }
}

// MARK: - Status

extension WatchServiceStatus {
    var color: Color {
        switch self {
        case .overdue: return WatchColors.statusOverdue
        case .dueSoon: return WatchColors.statusDueSoon
        case .good: return WatchColors.statusGood
        case .neutral: return WatchColors.statusNeutral
        }
    }

    /// Uppercase status word; empty for neutral rows.
    var label: String {
        switch self {
        case .overdue: return String(localized: "OVERDUE")
        case .dueSoon: return String(localized: "DUE SOON")
        case .good: return String(localized: "ON TRACK")
        case .neutral: return ""
        }
    }
}

/// Status shape, mirroring the iPhone app's StatusMark: overdue a filled
/// square, due soon an outlined square, on track a short rule. Hue is a
/// second channel, never the only one.
struct WatchStatusMark: View {
    let status: WatchServiceStatus
    var size: CGFloat = 8

    var body: some View {
        Group {
            switch status {
            case .overdue:
                Rectangle().fill(status.color)
            case .dueSoon:
                Rectangle().strokeBorder(status.color, lineWidth: max(1.5, size / 5))
            case .good:
                Rectangle().fill(status.color).frame(height: max(2, size / 3))
            case .neutral:
                Color.clear
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Status shape + word — the default status presentation.
struct WatchStatusTag: View {
    let status: WatchServiceStatus

    var body: some View {
        HStack(spacing: WatchSpacing.sm) {
            WatchStatusMark(status: status)
            Text(status.label)
                .font(.watchCaption.weight(.semibold))
                .foregroundStyle(status.color)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
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

// MARK: - Watch Section Divider

struct WatchDivider: View {
    var body: some View {
        Rectangle()
            .fill(WatchColors.gridLine)
            .frame(height: WatchColors.borderWidth)
            .accessibilityHidden(true)
    }
}
