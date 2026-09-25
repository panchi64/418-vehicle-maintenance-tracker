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

                // Success icon — decorative; the heading below says it.
                Image(systemName: "checkmark")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Theme.statusGood)
                    .accessibilityHidden(true)

                Text(L10n.importComplete)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.statusGood)
                    .tracking(2)
                    .accessibilityAddTraits(.isHeader)

                CSVImportStatTiles(stats: [
                    .init(value: "\(result.servicesCreated)", label: L10n.importStatServices),
                    .init(value: "\(result.logsCreated)", label: L10n.importStatLogs),
                    .init(value: Formatters.currencyWhole(result.totalCost), label: L10n.importStatTotal),
                ])
            }
            .frame(maxWidth: .infinity)
        }
    }
}
