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
            InstrumentSectionHeader(title: "Import Service History")

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Import your maintenance records from Fuelly, Drivvo, Simply Auto, or any CSV file.")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)

                Text("Supported formats: Fuelly, Drivvo, Simply Auto, Custom CSV")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
            }

            Button {
                onSelectFile()
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Select CSV File")
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
