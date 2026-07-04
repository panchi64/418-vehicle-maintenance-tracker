//
//  LastServiceReferenceCard.swift
//  checkpoint
//
//  Single history reference artifact shown once a service type is chosen
//  (R4). Informational only in Remind mode (onUseValues nil); in Record mode
//  it can port the last log's values onto the form.
//

import SwiftUI

struct LastServiceReferenceCard: View {
    let serviceName: String
    let log: ServiceLog
    var onUseValues: (() -> Void)? = nil

    private var summaryLine: String {
        var parts: [String] = []
        if let cost = log.cost {
            parts.append(Formatters.currencyWhole(cost))
        }
        parts.append(TimeSinceFormatter.full(from: log.performedDate))
        parts.append(Formatters.mileage(log.mileageAtService))
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.refCardLast(serviceName.uppercased()))
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            Text(summaryLine)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            if let onUseValues {
                Button(action: onUseValues) {
                    Text(L10n.refCardUseValues.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.refCardUseValues)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: Spacing.lg) {
            LastServiceReferenceCard(
                serviceName: "Oil Change",
                log: ServiceLog(performedDate: .now, mileageAtService: 32500, cost: 47),
                onUseValues: {}
            )

            LastServiceReferenceCard(
                serviceName: "Oil Change",
                log: ServiceLog(performedDate: .now, mileageAtService: 32500, cost: 47)
            )
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
