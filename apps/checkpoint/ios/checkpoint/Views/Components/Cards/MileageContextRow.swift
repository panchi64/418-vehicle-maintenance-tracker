//
//  MileageContextRow.swift
//  checkpoint
//
//  What the app already believes about the odometer, shown above the Update
//  Mileage field: the current estimate (when estimates are on) and the last
//  confirmed reading. Split from `MileageUpdateSheet` so the sheet holds only
//  the entry and its save path.
//

import SwiftUI

struct MileageContextRow: View {
    let vehicle: Vehicle

    private var hasEstimate: Bool {
        MileageEstimateSettings.shared.showEstimates
            && vehicle.isUsingEstimatedMileage
            && vehicle.estimatedMileage != nil
    }

    var body: some View {
        if hasEstimate {
            AdaptiveStack(spacing: Spacing.sm) {
                estimateCard
                lastConfirmedCard
            }
        } else if vehicle.mileageUpdatedAt != nil {
            lastConfirmedCard
        } else {
            noEstimateHint
        }
    }

    private var estimateCard: some View {
        card {
            label(L10n.mileageCurrentEstimate)

            if let estimate = vehicle.estimatedMileage {
                Text(Formatters.mileage(estimate))
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }

            if let confidence = vehicle.paceConfidence {
                HStack(spacing: Spacing.xs) {
                    CompactConfidenceBar(level: confidence)
                    Text(confidence.label)
                        .font(.brutalistLabel)
                        .foregroundStyle(confidence.color)
                        .tracking(1)
                }
            }
        }
    }

    private var lastConfirmedCard: some View {
        card {
            label(L10n.mileageLastConfirmed)

            Text(Formatters.mileage(vehicle.currentMileage))
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            Text(vehicle.mileageUpdateDescription)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var noEstimateHint: some View {
        card {
            label(L10n.mileageNoEstimate)

            Text(L10n.mileageNoEstimateHint)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .textCase(.uppercase)
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .tracking(1)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .accessibilityElement(children: .combine)
    }
}
