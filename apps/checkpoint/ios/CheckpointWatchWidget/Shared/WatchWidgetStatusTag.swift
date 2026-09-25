//
//  WatchWidgetStatusTag.swift
//  CheckpointWatchWidget
//
//  Status for complications as shape + word, mirroring the iPhone app's
//  StatusTag: overdue a filled square, due soon an outlined square, on track
//  a short rule. Watch faces render complications tinted (accented) as often
//  as in full color, so the shape and word carry status on their own.
//

import SwiftUI
import WidgetKit

extension WatchWidgetStatus {
    /// Uppercase status word; empty for neutral rows.
    var label: String {
        switch self {
        case .overdue: return String(localized: "OVERDUE")
        case .dueSoon: return String(localized: "DUE SOON")
        case .good: return String(localized: "ON TRACK")
        case .neutral: return ""
        }
    }

    /// SF Symbol mirroring the status shape, for text-and-image-only slots.
    var symbolName: String {
        switch self {
        case .overdue: return "square.fill"
        case .dueSoon: return "square"
        case .good: return "minus"
        case .neutral: return "circle.dotted"
        }
    }
}

/// Status shape only — use when the word is adjacent or spoken.
struct WatchWidgetStatusMark: View {
    let status: WatchWidgetStatus
    var size: CGFloat = 8

    @Environment(\.widgetRenderingMode) private var renderingMode

    private var tint: Color {
        renderingMode == .fullColor ? status.color : .primary
    }

    var body: some View {
        Group {
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
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Status shape + word.
struct WatchWidgetStatusTag: View {
    let status: WatchWidgetStatus

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        HStack(spacing: 4) {
            WatchWidgetStatusMark(status: status)
            Text(status.label)
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .foregroundStyle(renderingMode == .fullColor ? status.color : .primary)
                .lineLimit(1)
        }
        .widgetAccentable()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Display helpers

enum WatchWidgetDisplay {
    /// First word: "Oil Change" → "OIL"
    static func abbreviate(_ name: String) -> String {
        String(name.uppercased().split(separator: " ").first ?? "")
    }

    /// Compact due phrase ("500 MI", "500 MI OVER") from the structured
    /// fields, falling back to the phone-written description. Never parses
    /// `dueDescription`, which is in the phone's language.
    static func compactDue(for service: WatchWidgetService, entry: WatchWidgetEntry) -> String {
        if let dueMileage = service.dueMileage {
            let remainingMiles = dueMileage - entry.currentMileage
            let magnitude = entry.distanceUnit == "KM"
                ? Int((Double(abs(remainingMiles)) * 1.60934).rounded())
                : abs(remainingMiles)
            let amount = magnitude.formatted()
            let unit = entry.distanceUnit
            return remainingMiles < 0
                ? String(localized: "\(amount) \(unit) OVER")
                : "\(amount) \(unit)"
        }
        return service.dueDescription.uppercased()
    }

    /// "AS OF 3:40 PM" / "AS OF MAY 3" for a snapshot the phone synced a while
    /// back — mileage only moves when the phone syncs.
    static func asOfLabel(_ updatedAt: Date, now: Date) -> String {
        let stamp = Calendar.current.isDate(updatedAt, inSameDayAs: now)
            ? updatedAt.formatted(date: .omitted, time: .shortened)
            : updatedAt.formatted(.dateTime.month(.abbreviated).day())
        return String(localized: "AS OF \(stamp)").uppercased()
    }
}
