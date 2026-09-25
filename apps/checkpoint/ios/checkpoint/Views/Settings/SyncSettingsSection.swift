//
//  SyncSettingsSection.swift
//  checkpoint
//
//  iCloud sync in Settings: the toggle (the section's one control) and,
//  under it, a readout of whether records are actually reaching iCloud.
//

import SwiftUI

struct SyncSettingsSection: View {
    @State private var isEnabled: Bool = SyncSettings.shared.iCloudSyncEnabled

    var body: some View {
        let service = SyncStatusService.shared
        let display = SyncStatusDisplay.resolve(SyncStatusInputs(
            isEnabled: isEnabled,
            isActiveThisLaunch: SyncSettings.shared.isSyncActiveThisLaunch,
            account: service.account,
            state: service.syncState,
            lastSyncDate: service.lastSyncDate
        ))

        SettingsGroup(title: L10n.syncSectionTitle, footer: L10n.syncFooter) {
            // The data store is chosen at launch and can't be swapped under
            // open screens, so a flipped toggle says when it applies, right
            // under itself, in place of a status that no longer describes it.
            SettingsToggleRow(
                title: L10n.syncToggleTitle,
                subtitle: display == .pendingRestart ? L10n.syncTakesEffectNextLaunch : L10n.syncToggleSubtitle,
                isOn: $isEnabled
            )
            .onChange(of: isEnabled) { _, newValue in
                HapticService.shared.selectionChanged()
                SyncSettings.shared.iCloudSyncEnabled = newValue
            }

            if let display, display != .pendingRestart {
                SettingsRowDivider()
                SyncStatusRow(display: display)
            }
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
