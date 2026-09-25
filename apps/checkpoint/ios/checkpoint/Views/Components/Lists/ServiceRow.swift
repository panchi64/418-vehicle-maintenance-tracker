//
//  ServiceRow.swift
//  checkpoint
//
//  One scheduled service, in two lines:
//
//    Oil & Filter Change                  917 mi overdue
//    ■ OVERDUE  Due 32,500 mi or Jul 4
//
//  The name is the row's primary (15 Medium, primary ink). The remaining
//  figure trails it, where a scanning eye lands after reading the name. Status
//  is word + shape on line two — never color alone. It was three lines with a
//  20pt name (~84pt a row), so a list of names was a list of headings and the
//  Services tab showed four items above the fold.
//

import SwiftUI

struct ServiceRow: View {
    let service: Service
    let currentMileage: Int
    var isEstimatedMileage: Bool = false
    /// Inside a status-grouped list the group header carries the WORD, so the
    /// row keeps only the shape — "Overdue" above "■ OVERDUE" was a stutter.
    var groupedByStatus: Bool = false
    /// nil renders the row without its own tap target or chevron, for a
    /// `List` row wrapped in a `NavigationLink` that supplies both.
    var onTap: (() -> Void)? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var status: ServiceStatus {
        service.status(currentMileage: currentMileage)
    }

    private var isUrgent: Bool {
        status == .overdue || status == .dueSoon
    }

    var body: some View {
        if let onTap {
            content(showsChevron: true)
                .tappableCard(action: onTap)
                .accessibilityHint(L10n.rowViewDetailsHint)
                .accessibilityAddTraits(.isButton)
        } else {
            content(showsChevron: false)
        }
    }

    private func content(showsChevron: Bool) -> some View {
        // Computed once per render; each reads the status.
        let status = self.status
        let urgency = service.urgencyText(currentMileage: currentMileage)

        return HStack(spacing: Spacing.md) {
            // A full-height rule carries the status color as a third channel;
            // the tag on line two carries the word and the shape.
            Rectangle()
                .fill(status.color)
                .frame(width: status == .overdue ? 4 : 2)
                .frame(maxHeight: .infinity)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                AdaptiveStack(
                    verticalAlignment: .firstTextBaseline,
                    horizontalSpacing: Spacing.sm,
                    verticalSpacing: 2
                ) {
                    Text(service.name)
                        .font(.brutalistBodyEmphasis)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                        .multilineTextAlignment(.leading)
                        // Without this, List row sizing truncated at large
                        // type ("Tire Rotat…") despite the open line limit.
                        .fixedSize(horizontal: false, vertical: true)

                    AdaptiveSpacer()

                    if let urgency {
                        Text(urgency)
                            .font(.brutalistSecondary)
                            .foregroundStyle(isUrgent ? status.color : Theme.textTertiary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // First-baseline, so the mark sits with the due line's first
                // line when it wraps rather than centering on the block.
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    if isUrgent && !groupedByStatus {
                        StatusTag(status: status)
                    } else {
                        StatusMark(status: status)
                    }
                    Text(service.dueLine)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, Spacing.listItem)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(service.name)
        .accessibilityValue(accessibilityValue(status: status, urgency: urgency))
    }

    /// Status word first — weight, color and shape don't survive a screen
    /// reader — then the remaining figure and the due line.
    private func accessibilityValue(status: ServiceStatus, urgency: String?) -> String {
        let parts = [status == .neutral ? nil : L10n.readoutStatus(status), urgency, service.dueLine]
        return parts.compactMap { $0 }.joined(separator: ", ")
    }
}

// MARK: - Service Row Button Style

struct ServiceRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Rectangle()
                    .fill(configuration.isPressed ? Theme.backgroundSubtle : Color.clear)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)

    return ZStack {
        AtmosphericBackground()

        VStack(spacing: 0) {
            ForEach(services, id: \.name) { service in
                ServiceRow(service: service, currentMileage: vehicle.currentMileage) {}
                ListDivider()
            }
            ForEach(services, id: \.name) { service in
                ServiceRow(service: service, currentMileage: vehicle.currentMileage, groupedByStatus: true)
                ListDivider()
            }
        }
        .screenPadding()
    }
    .preferredColorScheme(.dark)
}
