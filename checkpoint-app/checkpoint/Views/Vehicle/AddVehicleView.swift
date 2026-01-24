//
//  AddVehicleView.swift
//  checkpoint
//
//  Form to add new vehicles with instrument cluster aesthetic
//

import SwiftUI
import SwiftData

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Form state
    @State private var name: String = ""
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: Int? = nil
    @State private var currentMileage: Int? = nil
    @State private var vin: String = ""
    @State private var tireSize: String = ""
    @State private var oilType: String = ""
    @State private var notes: String = ""

    // Validation
    private var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && year != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Vehicle Details Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Vehicle Details")

                            VStack(spacing: Spacing.md) {
                                InstrumentTextField(
                                    label: "Nickname",
                                    text: $name,
                                    placeholder: "Optional"
                                )

                                InstrumentTextField(
                                    label: "Make",
                                    text: $make,
                                    placeholder: "Toyota, Honda, Ford..."
                                )

                                InstrumentTextField(
                                    label: "Model",
                                    text: $model,
                                    placeholder: "Camry, Civic, F-150..."
                                )

                                InstrumentNumberField(
                                    label: "Year",
                                    value: $year,
                                    placeholder: "2024"
                                )
                            }
                        }

                        // Odometer Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Odometer")

                            InstrumentNumberField(
                                label: "Current Mileage",
                                value: $currentMileage,
                                placeholder: "0",
                                suffix: "mi"
                            )
                        }

                        // VIN Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Identification")

                            VStack(alignment: .leading, spacing: 4) {
                                InstrumentTextField(
                                    label: "VIN",
                                    text: $vin,
                                    placeholder: "Optional",
                                    autocapitalization: .characters
                                )

                                Text("17-character Vehicle Identification Number")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textTertiary)
                                    .padding(.leading, 4)
                            }
                        }

                        // Specifications Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Specifications")

                            VStack(spacing: Spacing.md) {
                                InstrumentTextField(
                                    label: "Tire Size",
                                    text: $tireSize,
                                    placeholder: "225/45R17 (Optional)"
                                )

                                InstrumentTextField(
                                    label: "Oil Type",
                                    text: $oilType,
                                    placeholder: "0W-20 Synthetic (Optional)"
                                )
                            }
                        }

                        // Notes Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Notes")

                            InstrumentTextEditor(
                                label: "Notes",
                                text: $notes,
                                placeholder: "Vehicle quirks, history, reminders..."
                            )
                        }

                        // Save button
                        Button("Add Vehicle") {
                            saveVehicle()
                        }
                        .buttonStyle(.primary)
                        .disabled(!isFormValid)
                        .padding(.top, Spacing.md)
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private func saveVehicle() {
        let vehicle = Vehicle(
            name: name,
            make: make,
            model: model,
            year: year ?? 0,
            currentMileage: currentMileage ?? 0,
            vin: vin.isEmpty ? nil : vin,
            tireSize: tireSize.isEmpty ? nil : tireSize,
            oilType: oilType.isEmpty ? nil : oilType,
            notes: notes.isEmpty ? nil : notes,
            mileageUpdatedAt: .now
        )
        modelContext.insert(vehicle)
        dismiss()
    }
}

#Preview {
    AddVehicleView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
