//
//  DistanceUnitPickerView.swift
//  checkpoint
//
//  Picker view for selecting distance unit (miles/kilometers)
//

import SwiftUI

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
                .brutalistBorder()
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
