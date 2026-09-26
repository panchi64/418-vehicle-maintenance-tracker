//
//  WidgetComponents.swift
//  CheckpointWidget
//
//  Building blocks shared by the small and medium widgets.
//

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Open Service

/// Makes `content` open `service`'s detail in the app when tapped
/// (`OpenServiceIntent` — no URL scheme). Rows without a service ID (the
/// marbete) or without a vehicle fall back to the widget's default tap,
/// which opens the app where it was.
struct OpenServiceButton<Content: View>: View {
    let service: WidgetService
    let vehicleID: String?
    @ViewBuilder let content: Content

    var body: some View {
        if let serviceID = service.serviceID, let vehicleID {
            Button(intent: OpenServiceIntent(serviceID: serviceID, vehicleID: vehicleID)) {
                content.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Hero

/// Label over the hero numeral and its unit — the one primary element of a
/// widget. Accentable, so tinted and clear rendering keep it the brightest thing.
struct WidgetHero: View {
    private let label: String
    private let value: String
    private let unit: String
    /// Unit centered under the value instead of beside it (a period's year)
    private let unitBelow: Bool
    private let numeralSize: CGFloat

    init(service: WidgetService, entry: ServiceEntry, numeralSize: CGFloat) {
        let displayMode = entry.configuration.mileageDisplayMode
        label = WidgetDisplayHelpers.displayLabel(for: service, displayMode: displayMode, currentMileage: entry.currentMileage)
        value = WidgetDisplayHelpers.displayValue(for: service, displayMode: displayMode, currentMileage: entry.currentMileage, distanceUnit: entry.distanceUnit)
        (unit, unitBelow) = WidgetDisplayHelpers.heroUnit(for: service, distanceUnit: entry.distanceUnit)
        self.numeralSize = numeralSize
    }

    var body: some View {
        let layout = unitBelow
            ? AnyLayout(VStackLayout(spacing: 0))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 4))

        VStack(spacing: 2) {
            Text(label)
                .font(.widgetLabel)
                .foregroundStyle(WidgetColors.textTertiary)
                .tracking(1)

            layout {
                WidgetNumeral(value, size: numeralSize)
                    .foregroundStyle(WidgetColors.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.widgetLabel)
                        .foregroundStyle(WidgetColors.textTertiary)
                        .tracking(1)
                        // Rigid, so the numeral steps down instead of the unit truncating
                        .fixedSize()
                }
            }
            .widgetAccentable()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
    }
}

/// The hero figure of a widget: bold mono at `size`, scaled with Dynamic Type
/// relative to `.largeTitle`, shrinking to fit rather than truncating.
///
/// Steps down through fixed sizes; word values like "MEDIADOS DE FEB" may
/// also take two lines split at the last space. A free-wrapping
/// `lineLimit(2)` Text doesn't compress to the height it's offered: the
/// wrapped hero pushed the medium widget's name and status past its edges.
/// Numbers have no spaces, so they only step down on one line.
struct WidgetNumeral: View {
    let text: String
    @ScaledMetric private var size: CGFloat

    init(_ text: String, size: CGFloat) {
        self.text = text
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    // Candidates are listed out, not generated: a ForEach inside ViewThatFits
    // trips a SwiftUI precondition, crashing the extension on every render so
    // WidgetKit falls back to the placeholder.
    var body: some View {
        let lines = WidgetDisplayHelpers.splitAtLastSpace(text)

        ViewThatFits {
            // Largest size first; at each size one line before two, so a
            // word value wraps only when that keeps it bigger.
            line(text, scale: 1)
            line(text, scale: 0.8)
            if let lines { twoLines(lines, scale: 0.8) }
            line(text, scale: 0.65)
            if let lines { twoLines(lines, scale: 0.65) }
            line(text, scale: 0.5)
            if let lines {
                twoLines(lines, scale: 0.5)
                twoLines(lines, scale: 0.4)
            }
            line(text, scale: 0.4)
                .minimumScaleFactor(0.5)
        }
    }

    private func twoLines(_ lines: (head: String, tail: String), scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            line(lines.head, scale: scale)
            line(lines.tail, scale: scale)
        }
    }

    private func line(_ string: String, scale: CGFloat) -> some View {
        Text(string)
            .font(.system(size: size * scale, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .lineLimit(1)
    }
}

// MARK: - Service Name

/// A service's name on one line, shrinking rather than truncating
/// ("CABIN AIR FI…"). 0.65 fits every preset name at default text size;
/// longer custom names or larger Dynamic Type can still truncate. Wrapping
/// instead would take height the hero needs.
struct WidgetServiceName: View {
    let name: String
    let font: Font

    var body: some View {
        Text(name.uppercased())
            .font(font)
            .foregroundStyle(WidgetColors.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
    }
}

// MARK: - Done Button

/// Logs the most urgent service from the widget (`WidgetMarkDoneIntent`).
/// Shown only for due-soon and overdue services with an ID and a vehicle.
struct WidgetDoneButton: View {
    let service: WidgetService
    let entry: ServiceEntry

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        if let serviceID = service.serviceID,
           let vehicleID = entry.vehicleID,
           service.status == .dueSoon || service.status == .overdue {
            Button(intent: WidgetMarkDoneIntent(
                serviceID: serviceID,
                vehicleID: vehicleID,
                mileage: entry.currentMileage
            )) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.widgetLabel.weight(.bold))
                    Text("DONE")
                        .font(.widgetLabel)
                        .tracking(0.5)
                }
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .overlay(
                    Rectangle()
                        .strokeBorder(tint.opacity(0.6), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .widgetAccentable()
            .accessibilityLabel(Text("Mark \(service.name) done"))
        }
    }

    private var tint: Color {
        renderingMode == .fullColor ? WidgetColors.statusGood : .primary
    }
}

// MARK: - Empty State

/// No vehicle yet, or nothing due.
struct WidgetEmptyState: View {
    let hasVehicle: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: hasVehicle ? "checkmark.circle" : "car.fill")
                .font(.title3)
                .foregroundStyle(WidgetColors.textSecondary)
                .accessibilityHidden(true)
            Text(hasVehicle ? "ALL CAUGHT UP" : "TAP TO SET UP")
                .font(.widgetBody)
                .foregroundStyle(WidgetColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .widgetAccentable()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - As-of Cue

/// "AS OF 3:40 PM" — how old the snapshot's figures are.
struct WidgetAsOfLabel: View {
    let entry: ServiceEntry

    var body: some View {
        if let updatedAt = entry.updatedAt {
            Text(WidgetDisplayHelpers.asOfLabel(updatedAt: updatedAt, entryDate: entry.date))
                .font(.widgetLabel)
                .foregroundStyle(WidgetColors.textTertiary)
                .lineLimit(1)
        }
    }
}
