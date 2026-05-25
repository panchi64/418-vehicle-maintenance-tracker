//
//  CSVImportPreviewStep.swift
//  checkpoint
//
//  Step 3 of CSV import wizard: preview parsed data and assign to vehicle
//

import SwiftUI

struct CSVImportPreviewStep: View {
    let preview: CSVImportPreview
    let vehicles: [Vehicle]
    @Binding var selectedVehicle: Vehicle?
    @Binding var createNewVehicle: Bool
    @Binding var newVehicleName: String
    @Binding var currentStep: CSVImportStep
    @Binding var errorMessage: String?
    let onImport: (CSVImportPreview) -> Void

    private var canImport: Bool {
        if createNewVehicle {
            return !newVehicleName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return selectedVehicle != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            InstrumentSectionHeader(title: "Import Summary")

            // Stats row
            HStack(spacing: Spacing.md) {
                statCard(
                    value: "\(preview.serviceCount)",
                    label: "SERVICES"
                )
                statCard(
                    value: "\(preview.logCount)",
                    label: "LOGS"
                )
                statCard(
                    value: Formatters.currencyWhole(preview.totalCost),
                    label: "TOTAL COST"
                )
            }

            // Service names
            InstrumentSectionHeader(title: "Services to Create")

            VStack(spacing: 0) {
                ForEach(Array(preview.serviceNames.enumerated()), id: \.offset) { index, name in
                    let count = preview.parsedRows.filter { $0.serviceName == name }.count

                    HStack {
                        Text(name)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Text("\(count) LOGS")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                    }
                    .padding(Spacing.md)

                    if index < preview.serviceNames.count - 1 {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: Theme.borderWidth)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()

            // Vehicle assignment
            InstrumentSectionHeader(title: "Assign to Vehicle")

            VStack(spacing: 0) {
                ForEach(vehicles) { vehicle in
                    Button {
                        selectedVehicle = vehicle
                        createNewVehicle = false
                    } label: {
                        HStack {
                            Text(vehicle.displayName)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            if selectedVehicle?.id == vehicle.id && !createNewVehicle {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: Theme.borderWidth)
                }

                // Create new vehicle option
                Button {
                    createNewVehicle = true
                    selectedVehicle = nil
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.accent)

                        Text("Create New Vehicle")
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        if createNewVehicle {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if createNewVehicle {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: Theme.borderWidth)

                    HStack {
                        TextField("Vehicle Name", text: $newVehicleName)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)
                            .textFieldStyle(.plain)
                    }
                    .padding(Spacing.md)
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()

            // Warnings
            if !preview.warnings.isEmpty {
                InstrumentSectionHeader(title: "Warnings (\(preview.warnings.count))")

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(preview.warnings.prefix(10)) { warning in
                        Text(warning.message)
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.statusDueSoon)
                            .tracking(1)
                    }
                    if preview.warnings.count > 10 {
                        Text("AND \(preview.warnings.count - 10) MORE...")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
            }

            // Buttons
            HStack(spacing: Spacing.md) {
                Button {
                    currentStep = .configure
                } label: {
                    Text("Back")
                }
                .buttonStyle(.secondary)

                Button {
                    onImport(preview)
                } label: {
                    Text("Import")
                }
                .buttonStyle(.primary)
                .disabled(!canImport)
                .opacity(canImport ? 1.0 : 0.5)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.statusOverdue)
            }
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
