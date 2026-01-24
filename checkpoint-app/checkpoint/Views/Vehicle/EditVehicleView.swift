//
//  EditVehicleView.swift
//  checkpoint
//
//  Form to edit existing vehicles with delete option
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
    @State private var year: String
    @State private var currentMileage: String
    @State private var vin: String

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _name = State(initialValue: vehicle.name)
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _year = State(initialValue: String(vehicle.year))
        _currentMileage = State(initialValue: String(vehicle.currentMileage))
        _vin = State(initialValue: vehicle.vin ?? "")
    }

    private var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && !year.isEmpty && Int(year) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Details") {
                    TextField("Nickname", text: $name)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                }

                Section("Odometer") {
                    TextField("Current Mileage", text: $currentMileage)
                        .keyboardType(.numberPad)
                }

                Section {
                    TextField("VIN", text: $vin)
                } footer: {
                    Text("17-character Vehicle Identification Number")
                }

                // Delete Section
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Vehicle")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(!isFormValid)
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
        vehicle.year = Int(year) ?? vehicle.year
        vehicle.currentMileage = Int(currentMileage) ?? vehicle.currentMileage
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
