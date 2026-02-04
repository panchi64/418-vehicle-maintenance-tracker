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
                        // DATA & SYNC
                        SyncSettingsSection()

                        // DISPLAY
                        displaySection

                        // ALERTS
                        alertsSection

                        // SERVICE BUNDLING
                        serviceBundlingSection

                        // WIDGETS
                        widgetSettingsSection

                        Spacer()
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.lg)
                }
            }
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone) { dismiss() }
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.settingsDisplay)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // Distance Unit
                NavigationLink {
                    DistanceUnitPickerView()
                } label: {
                    widgetSettingRow(
                        title: L10n.settingsDistanceUnit,
                        value: DistanceSettings.shared.unit.displayName
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Mileage Estimation
                MileageEstimatesToggle()
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.settingsAlerts)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // Due Soon Mileage Threshold
                NavigationLink {
                    DueSoonMileageThresholdPicker()
                } label: {
                    widgetSettingRow(
                        title: L10n.settingsDueSoonMileage,
                        value: "\(Formatters.mileageNumber(DueSoonSettings.shared.mileageThreshold)) \(DistanceSettings.shared.unit.abbreviation)"
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Due Soon Days Threshold
                NavigationLink {
                    DueSoonDaysThresholdPicker()
                } label: {
                    widgetSettingRow(
                        title: L10n.settingsDueSoonDays,
                        value: "\(DueSoonSettings.shared.daysThreshold) \(L10n.commonDays)"
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // App Icon Auto-change
                AppIconToggle()
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    // MARK: - Widget Settings Section

    private var widgetSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            Text(L10n.settingsWidgets)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // Default Vehicle
                NavigationLink {
                    WidgetVehiclePicker(vehicles: vehicles)
                } label: {
                    widgetSettingRow(
                        title: L10n.settingsDefaultVehicle,
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
                        title: L10n.settingsMileageDisplay,
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

    // MARK: - Service Bundling Section

    private var serviceBundlingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.settingsServiceBundling)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // Enable/Disable Toggle
                ServiceBundlingToggle()

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Mileage Window
                NavigationLink {
                    ClusteringMileageWindowPicker()
                } label: {
                    widgetSettingRow(
                        title: L10n.settingsMileageWindow,
                        value: "\(Formatters.mileageNumber(ClusteringSettings.shared.mileageWindow)) \(DistanceSettings.shared.unit.abbreviation)"
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Days Window
                NavigationLink {
                    ClusteringDaysWindowPicker()
                } label: {
                    widgetSettingRow(
                        title: L10n.settingsDaysWindow,
                        value: "\(ClusteringSettings.shared.daysWindow) \(L10n.commonDays)"
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
        return L10n.vehicleFirstVehicle
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

// MARK: - Distance Unit Picker View

struct DistanceUnitPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUnit: DistanceUnit = DistanceSettings.shared.unit

    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Spacing.lg) {
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
                .padding(.horizontal, Spacing.screenHorizontal)

                Spacer()
            }
            .padding(.top, Spacing.lg)
        }
        .navigationTitle(L10n.distanceUnitTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedUnit) { _, newUnit in
            Task { @MainActor in
                HapticService.shared.selectionChanged()
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

                    Text(unit == .miles ? L10n.distanceMilesDefault : L10n.distanceKilometersAbbr)
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
                Text(L10n.settingsAutomaticIcon)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                Text(L10n.settingsAutomaticIconDesc)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(Spacing.md)
        .onChange(of: isEnabled) { _, newValue in
            Task { @MainActor in
                HapticService.shared.selectionChanged()
                AppIconSettings.shared.autoChangeEnabled = newValue
                if !newValue {
                    AppIconService.shared.resetToDefaultIcon()
                }
            }
        }
    }
}

// MARK: - Service Bundling Toggle

struct ServiceBundlingToggle: View {
    @State private var isEnabled: Bool = ClusteringSettings.shared.isEnabled

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.settingsBundleSuggestions)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                Text(L10n.settingsBundleSuggestionsDesc)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(Spacing.md)
        .onChange(of: isEnabled) { _, newValue in
            Task { @MainActor in
                ClusteringSettings.shared.isEnabled = newValue
            }
        }
    }
}

// MARK: - Mileage Estimates Toggle

struct MileageEstimatesToggle: View {
    @State private var isEnabled: Bool = MileageEstimateSettings.shared.showEstimates

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.settingsMileageEstimation)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                Text(L10n.settingsMileageEstimationDesc)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(Spacing.md)
        .onChange(of: isEnabled) { _, newValue in
            Task { @MainActor in
                HapticService.shared.selectionChanged()
                MileageEstimateSettings.shared.showEstimates = newValue
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
