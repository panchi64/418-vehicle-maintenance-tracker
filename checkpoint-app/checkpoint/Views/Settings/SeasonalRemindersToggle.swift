//
//  SeasonalRemindersToggle.swift
//  checkpoint
//
//  Toggle for enabling/disabling seasonal maintenance alerts
//

import SwiftUI

struct SeasonalRemindersToggle: View {
    @State private var isEnabled: Bool = SeasonalSettings.shared.isEnabled

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Seasonal Alerts")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                Text("Show seasonal maintenance tips on the dashboard")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Theme.accent)
                .accessibilityLabel("Seasonal Alerts")
        }
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
        .onChange(of: isEnabled) { _, newValue in
            Task { @MainActor in
                HapticService.shared.selectionChanged()
                SeasonalSettings.shared.isEnabled = newValue
            }
        }
    }
}
