//
//  EditVehicleView.swift
//  checkpoint
//
//  Form to edit existing vehicles with delete option and instrument cluster aesthetic
//

import SwiftUI
import SwiftData

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var vehicle: Vehicle

    @State private var showDeleteConfirmation = false

    // Form state (initialize from vehicle)
    @State private var name: String
    @State private var make: String
    @State private var model: String
    @State private var year: Int?
    @State private var currentMileage: Int?
    @State private var vin: String

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _name = State(initialValue: vehicle.name)
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _year = State(initialValue: vehicle.year)
        _currentMileage = State(initialValue: vehicle.currentMileage)
        _vin = State(initialValue: vehicle.vin ?? "")
    }

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

                        // Save button
                        Button("Save Changes") {
                            saveChanges()
                        }
                        .buttonStyle(.primary)
                        .disabled(!isFormValid)
                        .padding(.top, Spacing.md)

                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Vehicle")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.statusOverdue)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.buttonHeight)
                            .background(Theme.statusOverdue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous)
                                    .strokeBorder(Theme.statusOverdue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .confirmationDialog(
                "Delete Vehicle?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteVehicle() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will also delete all services for this vehicle. This action cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        vehicle.name = name
        vehicle.make = make
        vehicle.model = model
        vehicle.year = year ?? vehicle.year
        vehicle.currentMileage = currentMileage ?? vehicle.currentMileage
        vehicle.vin = vin.isEmpty ? nil : vin
        dismiss()
    }

    private func deleteVehicle() {
        modelContext.delete(vehicle)
        dismiss()
    }
}

#Preview {
    @Previewable @State var vehicle = Vehicle(
        name: "Daily Driver",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500,
        vin: "1HGBH41JXMN109186"
    )

    EditVehicleView(vehicle: vehicle)
        .modelContainer(for: Vehicle.self, inMemory: true)
}
