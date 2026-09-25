//
//  CSVImportPickFileStep.swift
//  checkpoint
//
//  Step 1 of CSV import wizard: file selection
//

import SwiftUI

struct CSVImportPickFileStep: View {
    let onSelectFile: () -> Void
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            InstrumentSectionHeader(title: L10n.importPickTitle)

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(L10n.importPickBody)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)

                Text(L10n.importPickFormats)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
            }

            Button {
                onSelectFile()
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .accessibilityHidden(true)
                    Text(L10n.importPickButton)
                }
            }
            .buttonStyle(.primary)

            if let error = errorMessage {
                Text(error)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.statusOverdue)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceInstrument)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
                    )
            }
        }
    }
}
