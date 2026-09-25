//
//  WidgetStatusTag.swift
//  CheckpointWidget
//
//  The app's StatusTag, for widgets: status carried by a shape and a word,
//  never hue alone (docs/AESTHETIC.md [REQUIREMENT]). Overdue is a filled
//  square, due soon an outlined square, on track a short rule.
//
//  In tinted and clear (Liquid Glass) rendering, and on the Lock Screen, the
//  system flattens every color to the accent or white — the shape and word
//  are then the whole signal, so they must survive with no hue at all.
//

import SwiftUI
import WidgetKit

/// Status shape only — use when the status word is already adjacent.
struct WidgetStatusMark: View {
    let status: WidgetServiceStatus
    /// Side of the square; the rule is this wide and a third as tall.
    var size: CGFloat = 8

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        shape
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    /// Full color shows the status hue; every other mode draws in the
    /// foreground style so the tint can't wash it out.
    private var tint: Color {
        renderingMode == .fullColor ? status.color : .primary
    }

    @ViewBuilder
    private var shape: some View {
        switch status {
        case .overdue:
            Rectangle().fill(tint)
        case .dueSoon:
            Rectangle().strokeBorder(tint, lineWidth: max(1.5, size / 5))
        case .good:
            Rectangle().fill(tint).frame(height: max(2, size / 3))
        case .neutral:
            Color.clear
        }
    }
}

/// Status shape + word, the default status presentation.
struct WidgetStatusTag: View {
    let status: WidgetServiceStatus

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        HStack(spacing: 6) {
            WidgetStatusMark(status: status)
            Text(status.label)
                .font(.widgetLabel)
                .tracking(0.5)
                .foregroundStyle(renderingMode == .fullColor ? status.color : .primary)
                .lineLimit(1)
        }
        .widgetAccentable()
        .accessibilityElement(children: .combine)
    }
}

extension WidgetServiceStatus {
    /// Uppercase status word; empty for neutral rows, which carry no status.
    var label: String {
        switch self {
        case .overdue: return String(localized: "OVERDUE")
        case .dueSoon: return String(localized: "DUE SOON")
        case .good: return String(localized: "ON TRACK")
        case .neutral: return ""
        }
    }

    /// SF Symbol mirroring the status shape, for slots that render only text
    /// and images (inline accessories).
    var symbolName: String {
        switch self {
        case .overdue: return "square.fill"
        case .dueSoon: return "square"
        case .good: return "minus"
        case .neutral: return "circle.dotted"
        }
    }
}
