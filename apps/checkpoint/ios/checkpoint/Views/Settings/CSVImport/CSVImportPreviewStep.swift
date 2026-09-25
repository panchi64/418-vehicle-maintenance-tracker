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

    @FocusState private var isVehicleNameFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
            CSVImportStatTiles(stats: [
                .init(value: "\(preview.serviceCount)", label: "SERVICES"),
                .init(value: "\(preview.logCount)", label: "LOGS"),
                .init(value: Formatters.currencyWhole(preview.totalCost), label: "TOTAL COST"),
            ])

            // Service names
            InstrumentSectionHeader(title: "Services to Create")

            VStack(spacing: 0) {
                ForEach(Array(preview.serviceNames.enumerated()), id: \.offset) { index, name in
                    let count = preview.parsedRows.filter { $0.serviceName == name }.count

                    HStack(alignment: .firstTextBaseline) {
                        Text(name)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer(minLength: Spacing.sm)

                        Text("\(count) LOGS")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                    }
                    .padding(Spacing.md)
                    .accessibilityElement(children: .combine)

                    if index < preview.serviceNames.count - 1 {
                        SettingsRowDivider()
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()

            // Vehicle assignment
            InstrumentSectionHeader(title: "Assign to Vehicle")

            VStack(spacing: 0) {
                ForEach(vehicles) { vehicle in
                    SettingsOptionRow(
                        title: vehicle.displayName,
                        isSelected: selectedVehicle?.id == vehicle.id && !createNewVehicle
                    ) {
                        selectedVehicle = vehicle
                        createNewVehicle = false
                    }

                    SettingsRowDivider()
                }

                // Create new vehicle option
                SettingsOptionRow(
                    title: "Create New Vehicle",
                    isSelected: createNewVehicle
                ) {
                    createNewVehicle = true
                    selectedVehicle = nil
                }

                if createNewVehicle {
                    SettingsRowDivider()

                    HStack {
                        TextField("Vehicle Name", text: $newVehicleName)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)
                            .textFieldStyle(.plain)
                            .focused($isVehicleNameFocused)
                            .submitLabel(.done)
                            .onSubmit { isVehicleNameFocused = false }
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

            // Buttons — stacked at accessibility sizes so each label gets
            // the full width.
            let buttonLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: Spacing.sm))
                : AnyLayout(HStackLayout(spacing: Spacing.md))

            buttonLayout {
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
}
