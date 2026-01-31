//
//  ExportOptionsSheet.swift
//  checkpoint
//
//  Sheet for configuring PDF export options before generating.
//

import SwiftUI

struct ExportOptionsSheet: View {
    let vehicle: Vehicle
    let serviceLogs: [ServiceLog]
    @Binding var isExporting: Bool
    let onExport: (URL) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var includeTotal = true
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Header info
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("EXPORT SERVICE HISTORY")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    Text(vehicle.displayName)
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)

                    Text("\(serviceLogs.count) service\(serviceLogs.count == 1 ? "" : "s") recorded")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )

                // Options
                VStack(spacing: 0) {
                    Toggle(isOn: $includeTotal) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Include Total")
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Text("Show total amount spent")
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .tint(Theme.accent)
                    .padding(Spacing.md)
                }
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )

                // Error message
                if let error = exportError {
                    Text(error)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.statusOverdue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                // Export button
                Button {
                    generatePDF()
                } label: {
                    if isExporting {
                        ProgressView()
                            .tint(Theme.surfaceInstrument)
                    } else {
                        Text("Generate PDF")
                    }
                }
                .buttonStyle(.primary)
                .disabled(isExporting || serviceLogs.isEmpty)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .background(Theme.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func generatePDF() {
        isExporting = true
        exportError = nil

        // Generate PDF on main thread (service is @MainActor)
        let options = ServiceHistoryPDFService.ExportOptions(
            includeAttachments: false,
            includeTotal: includeTotal,
            includeCostPerMile: false
        )

        if let url = ServiceHistoryPDFService.shared.generatePDF(
            for: vehicle,
            serviceLogs: serviceLogs,
            options: options
        ) {
            isExporting = false
            dismiss()
            onExport(url)
        } else {
            isExporting = false
            exportError = "Failed to generate PDF. Please try again."
        }
    }
}

#Preview {
    ExportOptionsSheet(
        vehicle: Vehicle.sampleVehicle,
        serviceLogs: [],
        isExporting: .constant(false)
    ) { _ in }
    .preferredColorScheme(.dark)
}
