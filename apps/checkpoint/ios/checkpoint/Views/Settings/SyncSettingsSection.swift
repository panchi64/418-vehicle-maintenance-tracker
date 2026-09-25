//
//  SyncSettingsSection.swift
//  checkpoint
//
//  iCloud sync settings section for SettingsView
//  Combines sync toggle with detailed status display and error actions
//

import SwiftUI

struct SyncSettingsSection: View {
    @State private var syncService = SyncStatusService.shared
    @State private var isEnabled: Bool = SyncSettings.shared.iCloudSyncEnabled

    var body: some View {
        SettingsGroup(title: L10n.syncSectionTitle, footer: L10n.syncFooter) {
            syncToggleRow

            SettingsRowDivider()

            syncStatusRow
        }
    }

    // MARK: - Sync Toggle Row

    /// The data store is chosen at launch and can't be swapped under open
    /// screens, so a flipped toggle says when it applies, right under
    /// itself — not in an alert that has to be dismissed and then forgotten.
    private var takesEffectNextLaunch: Bool {
        isEnabled != SyncSettings.shared.isSyncActiveThisLaunch
    }

    private var syncToggleRow: some View {
        let needsAccount = !syncService.hasICloudAccount && isEnabled
        let subtitle: String
        if needsAccount {
            subtitle = L10n.syncSignInPrompt
        } else if takesEffectNextLaunch {
            subtitle = L10n.syncTakesEffectNextLaunch
        } else {
            subtitle = L10n.syncToggleSubtitle
        }

        return SettingsToggleRow(
            title: L10n.syncToggleTitle,
            subtitle: subtitle,
            subtitleColor: needsAccount ? Theme.statusOverdue : Theme.textTertiary,
            isOn: $isEnabled
        )
        .onChange(of: isEnabled) { _, newValue in
            SyncSettings.shared.iCloudSyncEnabled = newValue
            syncService.syncSettingChanged(enabled: newValue)
        }
    }

    // MARK: - Sync Status Row

    private var syncStatusRow: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    // The symbol differs per state; the text beside it says
                    // the same thing in words, so color is never alone.
                    statusIcon
                        .font(.body)
                        .accessibilityHidden(true)

                    Text(statusDisplayText)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                }

                if let lastSync = syncService.lastSyncDate {
                    Text(L10n.syncLastSynced(lastSync.formatted(.relative(presentation: .named))))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            // Action button for errors — kept out of the combined status
            // element so VoiceOver can reach and activate it.
            if let error = syncService.currentError, let actionLabel = error.actionLabel, isEnabled {
                Button {
                    handleErrorAction(error)
                } label: {
                    Text(actionLabel)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1)
                        .minimumTouchTarget()
                }
            }
        }
        .padding(Spacing.md)
        .frame(minHeight: TouchTarget.minimum)
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        if !isEnabled {
            Image(systemName: "icloud.slash")
                .foregroundStyle(Theme.textTertiary)
        } else {
            switch syncService.syncState {
            case .idle, .synced:
                Image(systemName: "checkmark.icloud")
                    .foregroundStyle(Theme.statusGood)
            case .syncing:
                Image(systemName: "arrow.triangle.2.circlepath.icloud")
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.rotate, options: .repeating)
            case .error(let error):
                Image(systemName: error.systemImage)
                    .foregroundStyle(error.iconColor)
            case .disabled, .noAccount:
                Image(systemName: "icloud.slash")
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    // MARK: - Status Display Text

    private var statusDisplayText: String {
        isEnabled ? syncService.syncState.displayText : L10n.syncDisabled
    }

    // MARK: - Error Actions

    private func handleErrorAction(_ error: SyncError) {
        switch error {
        case .notSignedIn:
            syncService.openSettings()
        case .quotaExceeded:
            syncService.openStorageSettings()
        default:
            break
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        ScrollView {
            SyncSettingsSection()
                .padding()
        }
    }
    .preferredColorScheme(.dark)
}
