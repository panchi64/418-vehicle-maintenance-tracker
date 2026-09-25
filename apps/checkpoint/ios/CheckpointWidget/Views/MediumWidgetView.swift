//
//  MediumWidgetView.swift
//  CheckpointWidget
//
//  Medium widget: the next service as the hero, the two after it as a list
//  Brutalist-Tech-Modernist aesthetic
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: ServiceEntry

    private var displayMode: MileageDisplayMode {
        entry.configuration.mileageDisplayMode
    }

    /// Services after the first (for the right panel)
    private var otherServices: [WidgetService] {
        Array(entry.services.dropFirst().prefix(2))
    }

    var body: some View {
        HStack(spacing: 0) {
            leftPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Vertical divider (brutalist - 2px solid line)
            Rectangle()
                .fill(WidgetColors.gridLine)
                .frame(width: WidgetColors.borderWidth)
                .accessibilityHidden(true)

            rightPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    // MARK: - Left Panel (Next Up Focus)

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.vehicleName.uppercased())
                .font(.widgetHeadline)
                .foregroundStyle(WidgetColors.textPrimary)
                .lineLimit(1)

            if let service = entry.services.first {
                OpenServiceButton(service: service, vehicleID: entry.vehicleID) {
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer(minLength: 0)

                        WidgetHero(
                            label: WidgetDisplayHelpers.displayLabel(for: service, displayMode: displayMode, currentMileage: entry.currentMileage),
                            value: WidgetDisplayHelpers.displayValue(for: service, displayMode: displayMode, currentMileage: entry.currentMileage, distanceUnit: entry.distanceUnit),
                            unit: WidgetDisplayHelpers.displayUnit(for: service, distanceUnit: entry.distanceUnit),
                            numeralSize: 40
                        )

                        Spacer(minLength: 0)

                        Text(service.name.uppercased())
                            .font(.widgetBody)
                            .foregroundStyle(WidgetColors.textPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                HStack(spacing: 0) {
                    WidgetStatusTag(status: service.status)
                    Spacer(minLength: 4)
                    WidgetDoneButton(service: service, entry: entry)
                }
            } else {
                WidgetEmptyState(hasVehicle: entry.vehicleID != nil)
            }
        }
        .padding(.trailing, 12)
    }

    // MARK: - Right Panel (Other Services)

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if otherServices.isEmpty {
                Spacer(minLength: 0)
                Text("NOTHING ELSE DUE")
                    .font(.widgetBody)
                    .foregroundStyle(WidgetColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            } else {
                Text("UPCOMING")
                    .font(.widgetLabel)
                    .foregroundStyle(WidgetColors.textTertiary)
                    .tracking(1)

                ForEach(otherServices) { service in
                    OpenServiceButton(service: service, vehicleID: entry.vehicleID) {
                        upcomingRow(service)
                    }
                }
            }

            Spacer(minLength: 0)

            WidgetAsOfLabel(entry: entry)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
    }

    /// Name on top; status word and compact due phrase beneath, so status
    /// reads as shape + word here too.
    private func upcomingRow(_ service: WidgetService) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(service.name.uppercased())
                .font(.widgetBody)
                .foregroundStyle(WidgetColors.textPrimary)
                .lineLimit(1)

            // One line when both fit; otherwise the due phrase drops beneath.
            // Sharing a line, a date-based phrase truncated both halves
            // ("ON TRA… MID FEB 2…"), and dropping the word would leave
            // status as shape alone.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    WidgetStatusTag(status: service.status)
                    upcomingDue(service)
                }
                VStack(alignment: .leading, spacing: 1) {
                    WidgetStatusTag(status: service.status)
                    upcomingDue(service)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func upcomingDue(_ service: WidgetService) -> some View {
        Text(WidgetDisplayHelpers.compactDue(for: service, currentMileage: entry.currentMileage, distanceUnit: entry.distanceUnit))
            .font(.widgetLabel)
            .foregroundStyle(WidgetColors.textTertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

#Preview(as: .systemMedium) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
