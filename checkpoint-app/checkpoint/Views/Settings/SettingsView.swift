//
//  SettingsView.swift
//  checkpoint
//
//  Settings screen with distance unit picker
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Distance Unit Section
                        distanceUnitSection

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

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
