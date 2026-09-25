//
//  SyncStatusRow.swift
//  checkpoint
//
//  A readout under the iCloud Sync toggle: syncing, last synced, couldn't
//  sync (and why), or iCloud unavailable. Secondary to the toggle above it;
//  the state is always a word plus a symbol, never color alone. The one
//  action — Open Settings when there is no usable iCloud account — is the
//  only thing here that can be tapped.
//

import SwiftUI
import UIKit

struct SyncStatusRow: View {
    let display: SyncStatusDisplay

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        AdaptiveStack(horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.xs) {
            // "Last synced 2 minutes ago" has to age while Settings is open.
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                status
            }

            AdaptiveSpacer()

            // Kept out of the combined status so VoiceOver can reach it.
            if display == .unavailable {
                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    Text(L10n.syncActionOpenSettings)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1)
                        .textCase(.uppercase)
                        .minimumTouchTarget()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.md)
        .frame(minHeight: TouchTarget.minimum)
        // Coming back from the Settings app is when the account changes.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await SyncStatusService.shared.checkAccountStatus()
        }
    }

    private var status: some View {
        let line = statusLine
        let reason = failureReason

        return HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            symbol
                .font(.brutalistSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(line)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)

                if let reason {
                    Text(reason)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reason.map { L10n.syncStatusAccessibility(line, reason: $0) }
            ?? L10n.syncStatusAccessibility(line))
    }

    @ViewBuilder
    private var symbol: some View {
        switch display {
        case .syncing:
            ProgressView()
                .controlSize(.small)
                .tint(Theme.textSecondary)
        case .upToDate(let lastSynced):
            Image(systemName: lastSynced == nil ? "icloud" : "checkmark.icloud")
                .foregroundStyle(Theme.textTertiary)
        case .failed(let error):
            Image(systemName: error.systemImage)
                .foregroundStyle(error.iconColor)
        case .unavailable, .pendingRestart:
            Image(systemName: "icloud.slash")
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var statusLine: String {
        switch display {
        case .syncing:
            return L10n.syncStateSyncing
        case .upToDate(let lastSynced?):
            return L10n.syncLastSynced(lastSynced.formatted(.relative(presentation: .named)))
        case .upToDate(nil):
            return L10n.syncStatusNeverSynced
        case .failed:
            return L10n.syncStatusFailed
        case .unavailable, .pendingRestart:
            return L10n.syncStatusUnavailable
        }
    }

    private var failureReason: String? {
        guard case .failed(let error) = display else { return nil }
        return SyncStatusDisplay.failureReason(error)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: 0) {
            SyncStatusRow(display: .upToDate(lastSynced: .now.addingTimeInterval(-120)))
            SyncStatusRow(display: .syncing)
            SyncStatusRow(display: .failed(.quotaExceeded))
            SyncStatusRow(display: .failed(.networkUnavailable))
            SyncStatusRow(display: .unavailable)
        }
        .padding()
    }
}
