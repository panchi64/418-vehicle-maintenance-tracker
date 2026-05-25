//
//  VehicleMultiPicker.swift
//  checkpoint
//
//  Multi-select sheet for linking a Document to one or more vehicles.
//
//  Locked vehicle IDs render dimmed and cannot be toggled off — used to
//  pin "the current vehicle" so the user can only add other links from
//  the document add/edit flow.
//

import SwiftUI

struct VehicleMultiPicker: View {
    @Environment(\.dismiss) private var dismiss

    let allVehicles: [Vehicle]
    @Binding var selection: Set<UUID>
    var lockedVehicleIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(allVehicles.enumerated()), id: \.element.id) { index, vehicle in
                            row(for: vehicle)

                            if index < allVehicles.count - 1 {
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: 1)
                            }
                        }
                    }
                    .background(Theme.surfaceInstrument)
                    .brutalistBorder()
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle("Link Vehicles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .toolbarButtonStyle()
                }
            }
        }
    }

    private func row(for vehicle: Vehicle) -> some View {
        let isSelected = selection.contains(vehicle.id)
        let isLocked = lockedVehicleIDs.contains(vehicle.id)

        return Button {
            guard !isLocked else { return }
            if isSelected {
                selection.remove(vehicle.id)
            } else {
                selection.insert(vehicle.id)
            }
            HapticService.shared.selectionChanged()
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vehicle.displayName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    Text(vehicleSubtitle(for: vehicle))
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: Spacing.sm)

                checkbox(isSelected: isSelected, isLocked: isLocked)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.listItem)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityLabel(vehicle.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func vehicleSubtitle(for vehicle: Vehicle) -> String {
        let trimmed = "\(vehicle.make) \(vehicle.model)".trimmingCharacters(in: .whitespaces)
        if vehicle.year > 0 {
            return "\(trimmed) \u{2022} \(vehicle.year)"
        }
        return trimmed
    }

    private func checkbox(isSelected: Bool, isLocked: Bool) -> some View {
        ZStack {
            Rectangle()
                .strokeBorder(isSelected ? Theme.accent : Theme.gridLine, lineWidth: 2)
                .frame(width: 22, height: 22)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isLocked ? Theme.textTertiary : Theme.accent)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: Set<UUID> = []

    let vehicles = [
        Vehicle(name: "Daily Driver", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500),
        Vehicle(name: "Weekend", make: "Honda", model: "Civic", year: 2020, currentMileage: 18000),
        Vehicle(name: "", make: "Ford", model: "F-150", year: 2019, currentMileage: 90000),
    ]

    let locked: Set<UUID> = [vehicles[0].id]

    return VehicleMultiPicker(
        allVehicles: vehicles,
        selection: $selection,
        lockedVehicleIDs: locked
    )
    .preferredColorScheme(.dark)
}
