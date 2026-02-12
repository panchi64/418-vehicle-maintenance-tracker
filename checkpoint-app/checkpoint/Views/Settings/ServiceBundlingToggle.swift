//
//  ServiceBundlingToggle.swift
//  checkpoint
//
//  Toggle for enabling/disabling service bundling suggestions
//

import SwiftUI

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
