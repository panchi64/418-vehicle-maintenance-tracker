//
//  AddVehicleView.swift
//  checkpoint
//
//  Form to add new vehicles to the app
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
    @State private var year: String = ""
    @State private var currentMileage: String = ""
    @State private var vin: String = ""

    // Validation
    private var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && !year.isEmpty && Int(year) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Vehicle Details") {
                    TextField("Nickname (optional)", text: $name)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                }

                // Mileage Section
                Section("Odometer") {
                    TextField("Current Mileage", text: $currentMileage)
                        .keyboardType(.numberPad)
                }

                // Optional VIN Section
                Section {
                    TextField("VIN (optional)", text: $vin)
                } footer: {
                    Text("17-character Vehicle Identification Number")
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .foregroundStyle(Theme.accent)
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private func saveVehicle() {
        let vehicle = Vehicle(
            name: name,
            make: make,
            model: model,
            year: Int(year) ?? 0,
            currentMileage: Int(currentMileage) ?? 0,
            vin: vin.isEmpty ? nil : vin
        )
        modelContext.insert(vehicle)
        dismiss()
    }
}

#Preview {
    AddVehicleView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
