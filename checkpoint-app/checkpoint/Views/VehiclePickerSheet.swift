//
//  VehiclePickerSheet.swift
//  checkpoint
//
//  Sheet for selecting between vehicles with instrument cluster aesthetic
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
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Vehicles list
                        VStack(spacing: 0) {
                            ForEach(vehicles) { vehicle in
                                vehicleRow(vehicle)

                                if vehicle.id != vehicles.last?.id {
                                    Rectangle()
                                        .fill(Theme.gridLine)
                                        .frame(height: 1)
                                        .padding(.leading, Spacing.md)
                                }
                            }
                        }
                        .background(Theme.surfaceInstrument)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Theme.gridLine, lineWidth: 1)
                        )

                        // Add vehicle button
                        Button {
                            dismiss()
                            onAddVehicle()
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.accent)

                                Text("Add Vehicle")
                                    .font(.instrumentBody)
                                    .foregroundStyle(Theme.accent)

                                Spacer()
                            }
                            .padding(Spacing.md)
                            .background(Theme.surfaceInstrument)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Theme.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.instrument)
                        .accessibilityLabel("Add new vehicle")
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .applyGlassBackground()
    }

    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        Button {
            selectedVehicle = vehicle
            dismiss()
        } label: {
            HStack(spacing: Spacing.md) {
                // Vehicle icon with status
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "car.side.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.displayName.uppercased())
                        .font(.custom("Barlow-SemiBold", size: 16))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(0.5)

                    Text("\(String(vehicle.year)) \(vehicle.make) \(vehicle.model)")
                        .font(.instrumentLabel)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedVehicle?.id == vehicle.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(ServiceRowButtonStyle())
        .accessibilityLabel(vehicle.displayName)
        .accessibilityHint(selectedVehicle?.id == vehicle.id ? "Currently selected" : "Double tap to select")
    }
}

// MARK: - Glass Background Modifier (iOS 26+)

extension View {
    @ViewBuilder
    func applyGlassBackground() -> some View {
        if #available(iOS 26, *) {
            self.presentationBackground(.regularMaterial)
        } else {
            self
        }
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
