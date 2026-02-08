//
//  AnalyticsSettingsSection.swift
//  checkpoint
//
//  Settings section for analytics opt-in/opt-out toggle
//

import SwiftUI

struct AnalyticsSettingsSection: View {
    var sectionTitle: String = "ANALYTICS"
    @State private var isEnabled: Bool = AnalyticsSettings.shared.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(sectionTitle)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Usage Analytics")
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Helps us improve Checkpoint. No personal data is ever collected.")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                        .tint(Theme.accent)
                }
                .padding(Spacing.md)
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
        .onChange(of: isEnabled) { _, newValue in
            Task { @MainActor in
                HapticService.shared.selectionChanged()
                AnalyticsService.shared.setEnabled(newValue)
            }
        }
    }
}
