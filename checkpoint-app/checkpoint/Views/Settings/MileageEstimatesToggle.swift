//
//  MileageEstimatesToggle.swift
//  checkpoint
//
//  Toggle for enabling/disabling mileage estimation display
//

import SwiftUI

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
