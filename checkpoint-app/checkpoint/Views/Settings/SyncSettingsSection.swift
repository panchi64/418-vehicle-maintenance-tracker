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
    @State private var showRestartAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            Text("ICLOUD SYNC")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // iCloud Sync toggle
                syncToggleRow

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Sync status row with detailed icons and actions
                syncStatusRow
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )

            // Info text
            Text("Syncs your vehicles and maintenance data across your Apple devices via iCloud.")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, Spacing.xs)
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please restart the app for sync changes to take effect.")
        }
    }

    // MARK: - Sync Toggle Row

    private var syncToggleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("iCloud Sync")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                if !syncService.hasICloudAccount && isEnabled {
                    Text("Sign in to iCloud in Settings")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.statusOverdue)
                } else {
                    Text("Free • No account required")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Theme.accent)
                .accessibilityLabel("iCloud Sync")
        }
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
        .onChange(of: isEnabled) { _, newValue in
            Task { @MainActor in
                SyncSettings.shared.iCloudSyncEnabled = newValue
                syncService.syncSettingChanged(enabled: newValue)
                showRestartAlert = true
            }
        }
    }

    // MARK: - Sync Status Row

    private var syncStatusRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.sm) {
                    // Status icon
                    statusIcon

                    Text(statusDisplayText)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                }

                // Last sync time
                if let lastSync = syncService.lastSyncDate {
                    Text("Last synced \(lastSync.formatted(.relative(presentation: .named)))")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer()

            // Action button for errors
            if let error = syncService.currentError, let actionLabel = error.actionLabel, isEnabled {
                Button {
                    handleErrorAction(error)
                } label: {
                    Text(actionLabel)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sync status: \(statusDisplayText)")
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        if !isEnabled {
            // Sync disabled
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
        if !isEnabled {
            return "Sync disabled"
        }
        return syncService.syncState.displayText
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
