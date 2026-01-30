//
//  SettingsView.swift
//  checkpoint
//
//  Settings screen with distance unit picker, app icon preferences, and widget settings
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // App Icon Section
                        appIconSection

                        // Distance Unit Section
                        distanceUnitSection

                        // Widget Settings Section
                        widgetSettingsSection

                        Spacer()
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.lg)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: - App Icon Section

    private var appIconSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("APP ICON")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            AppIconToggle()
        }
    }

    // MARK: - Distance Unit Section

    private var distanceUnitSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            Text("DISTANCE UNIT")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            // Unit picker
            DistanceUnitPicker()
        }
    }

    // MARK: - Widget Settings Section

    private var widgetSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            Text("WIDGETS")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // Default Vehicle
                NavigationLink {
                    WidgetVehiclePicker(vehicles: vehicles)
                } label: {
                    widgetSettingRow(
                        title: "Default Vehicle",
                        value: selectedVehicleName
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Mileage Display Mode
                NavigationLink {
                    WidgetMileageModePicker()
                } label: {
                    widgetSettingRow(
                        title: "Mileage Display",
                        value: WidgetSettingsManager.shared.mileageDisplayMode.displayName
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    private var selectedVehicleName: String {
        if let vehicleID = WidgetSettingsManager.shared.defaultVehicleID,
           let vehicle = vehicles.first(where: { $0.id.uuidString == vehicleID }) {
            return vehicle.name
        }
        return "First Vehicle"
    }

    private func widgetSettingRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Text(value)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Distance Unit Picker

struct DistanceUnitPicker: View {
    @State private var selectedUnit: DistanceUnit = DistanceSettings.shared.unit

    var body: some View {
        VStack(spacing: 0) {
            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                unitRow(for: unit)

                if unit != DistanceUnit.allCases.last {
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
        .onChange(of: selectedUnit) { _, newUnit in
            Task { @MainActor in
                DistanceSettings.shared.unit = newUnit
            }
        }
    }

    private func unitRow(for unit: DistanceUnit) -> some View {
        Button {
            selectedUnit = unit
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(unit.displayName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text(unit == .miles ? "mi (default)" : "km")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedUnit == unit {
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

// MARK: - App Icon Toggle

struct AppIconToggle: View {
    @State private var isEnabled: Bool = AppIconSettings.shared.autoChangeEnabled

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Automatic Icon")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                Text("Changes icon based on service urgency")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
        .onChange(of: isEnabled) { _, newValue in
            Task { @MainActor in
                AppIconSettings.shared.autoChangeEnabled = newValue
                if !newValue {
                    AppIconService.shared.resetToDefaultIcon()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
