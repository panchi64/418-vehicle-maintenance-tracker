//
//  SyncSettingsSection.swift
//  checkpoint
//
//  iCloud sync settings section for SettingsView
//

import SwiftUI

struct SyncSettingsSection: View {
    @State private var syncService = SyncStatusService.shared
    @State private var isEnabled: Bool = SyncSettings.shared.iCloudSyncEnabled
    @State private var showRestartAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            Text("DATA & SYNC")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // iCloud Sync toggle
                syncToggleRow

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Sync status row
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
        }
        .padding(Spacing.md)
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
                Text("Status")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: Spacing.xs) {
                    statusIndicator
                    Text(syncService.syncState.displayText)
                        .font(.brutalistSecondary)
                        .foregroundStyle(statusColor)
                }
            }

            Spacer()

            if let lastSync = syncService.lastSyncDescription {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last synced")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                    Text(lastSync)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        switch syncService.syncState {
        case .syncing:
            ProgressView()
                .scaleEffect(0.7)
                .tint(Theme.accent)
        case .synced, .idle:
            Circle()
                .fill(Theme.statusGood)
                .frame(width: 8, height: 8)
        case .error, .noAccount:
            Circle()
                .fill(Theme.statusOverdue)
                .frame(width: 8, height: 8)
        case .disabled:
            Circle()
                .fill(Theme.textTertiary)
                .frame(width: 8, height: 8)
        }
    }

    private var statusColor: Color {
        switch syncService.syncState {
        case .synced, .idle:
            return Theme.statusGood
        case .syncing:
            return Theme.accent
        case .error, .noAccount:
            return Theme.statusOverdue
        case .disabled:
            return Theme.textTertiary
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
