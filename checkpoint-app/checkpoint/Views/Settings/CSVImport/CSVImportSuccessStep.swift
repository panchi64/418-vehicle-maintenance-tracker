//
//  CSVImportSuccessStep.swift
//  checkpoint
//
//  Step 4 of CSV import wizard: success confirmation with stats
//

import SwiftUI

struct CSVImportSuccessStep: View {
    let result: CSVImportResult?

    var body: some View {
        if let result = result {
            VStack(spacing: Spacing.lg) {
                Spacer()
                    .frame(height: Spacing.xl)

                // Success icon
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Theme.statusGood)

                Text("IMPORT COMPLETE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.statusGood)
                    .tracking(2)

                // Stats
                HStack(spacing: Spacing.md) {
                    statCard(
                        value: "\(result.servicesCreated)",
                        label: "SERVICES"
                    )
                    statCard(
                        value: "\(result.logsCreated)",
                        label: "LOGS"
                    )
                    statCard(
                        value: Formatters.currencyWhole(result.totalCost),
                        label: "TOTAL"
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }
}
