//
//  VehiclePickerSheet.swift
//  checkpoint
//
//  Sheet for selecting between vehicles
//

import SwiftUI
import SwiftData

struct VehiclePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]

    @Binding var selectedVehicle: Vehicle?
    let onAddVehicle: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(vehicles) { vehicle in
                        Button {
                            selectedVehicle = vehicle
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(vehicle.displayName)
                                        .font(.bodyText)
                                        .foregroundStyle(Theme.textPrimary)

                                    Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }

                                Spacer()

                                if selectedVehicle?.id == vehicle.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(vehicle.displayName)
                        .accessibilityHint(selectedVehicle?.id == vehicle.id ? "Currently selected" : "Double tap to select")
                    }
                }

                Section {
                    Button {
                        dismiss()
                        onAddVehicle()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Theme.accent)

                            Text("Add vehicle")
                                .font(.bodyText)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .accessibilityLabel("Add new vehicle")
                }
            }
            .navigationTitle("Select vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    @Previewable @State var selected: Vehicle? = nil

    VehiclePickerSheet(
        selectedVehicle: $selected,
        onAddVehicle: { print("Add vehicle") }
    )
    .modelContainer(for: Vehicle.self, inMemory: true)
}
