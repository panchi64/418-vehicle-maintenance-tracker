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
    let label: String
    let value: String
    let unit: String
    let numeralSize: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.widgetLabel)
                .foregroundStyle(WidgetColors.textTertiary)
                .tracking(1)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                WidgetNumeral(value, size: numeralSize)
                    .foregroundStyle(WidgetColors.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.widgetLabel)
                        .foregroundStyle(WidgetColors.textTertiary)
                        .tracking(1)
                }
            }
            .widgetAccentable()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Done Button

/// Logs the most urgent service from the widget (`MarkServiceDoneIntent`).
/// Shown only for due-soon and overdue services with an ID and a vehicle.
struct WidgetDoneButton: View {
    let service: WidgetService
    let entry: ServiceEntry

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        if let serviceID = service.serviceID,
           let vehicleID = entry.vehicleID,
           service.status == .dueSoon || service.status == .overdue {
            Button(intent: MarkServiceDoneIntent(
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
