//
//  WidgetVehiclePicker.swift
//  checkpoint
//
//  Vehicle picker for widget default settings
//

import SwiftUI

struct WidgetVehiclePicker: View {
    let vehicles: [Vehicle]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVehicleID: String?

    init(vehicles: [Vehicle]) {
        self.vehicles = vehicles
        // Initialize with current setting
        _selectedVehicleID = State(initialValue: WidgetSettingsManager.shared.defaultVehicleID)
    }

    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Section header
                    Text("DEFAULT VEHICLE")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    VStack(spacing: 0) {
                        // "First Vehicle" option (nil selection)
                        vehicleRow(
                            name: "First Vehicle",
                            subtitle: "Use the first available vehicle",
                            vehicleID: nil
                        )

                        if !vehicles.isEmpty {
                            Rectangle()
                                .fill(Theme.gridLine)
                                .frame(height: Theme.borderWidth)
                        }

                        // Vehicle options
                        ForEach(Array(vehicles.enumerated()), id: \.element.id) { index, vehicle in
                            vehicleRow(
                                name: vehicle.displayName,
                                subtitle: "\(vehicle.year) \(vehicle.make) \(vehicle.model)",
                                vehicleID: vehicle.id.uuidString
                            )

                            if index < vehicles.count - 1 {
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: Theme.borderWidth)
                            }
                        }
                    }
                    .background(Theme.surfaceInstrument)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                    )

                    Spacer()
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
        }
        .navigationTitle("Default Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedVehicleID) { _, newValue in
            Task { @MainActor in
                WidgetSettingsManager.shared.defaultVehicleID = newValue
            }
        }
    }

    private func vehicleRow(name: String, subtitle: String, vehicleID: String?) -> some View {
        Button {
            selectedVehicleID = vehicleID
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text(subtitle)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedVehicleID == vehicleID {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        WidgetVehiclePicker(vehicles: [])
    }
    .preferredColorScheme(.dark)
}
