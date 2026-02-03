//
//  DueSoonMileageThresholdPicker.swift
//  checkpoint
//
//  Picker view for selecting the "due soon" mileage threshold
//

import SwiftUI

struct DueSoonMileageThresholdPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedThreshold: Int = DueSoonSettings.shared.mileageThreshold

    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(L10n.dueSoonMileageDesc)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Spacing.screenHorizontal)

                VStack(spacing: 0) {
                    ForEach(DueSoonSettings.mileageOptions, id: \.self) { option in
                        thresholdRow(for: option)

                        if option != DueSoonSettings.mileageOptions.last {
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
        .navigationTitle(L10n.dueSoonMileageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedThreshold) { _, newValue in
            Task { @MainActor in
                DueSoonSettings.shared.mileageThreshold = newValue
            }
        }
    }

    private func thresholdRow(for option: Int) -> some View {
        Button {
            HapticService.shared.selectionChanged()
            selectedThreshold = option
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Formatters.mileageNumber(option)) \(DistanceSettings.shared.unit.abbreviation)")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    if option == 750 {
                        Text(L10n.dueSoonDefault)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer()

                if selectedThreshold == option {
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
        DueSoonMileageThresholdPicker()
    }
    .preferredColorScheme(.dark)
}
