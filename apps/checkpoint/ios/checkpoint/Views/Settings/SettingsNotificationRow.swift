//
//  SettingsNotificationRow.swift
//  checkpoint
//
//  Whether reminders can reach the user — Allowed, Off, or Not Asked — and
//  the one action that changes it: ask (never asked) or open the system's
//  notification settings (turned off, which only iOS can undo). Every
//  threshold in the Reminders group is moot while this is off, so it leads
//  the group.
//

import SwiftUI
import UIKit

struct SettingsNotificationRow: View {
    @Environment(\.scenePhase) private var scenePhase

    private var permission: NotificationPermission {
        NotificationService.shared.permission
    }

    private var statusText: String {
        switch permission {
        case .allowed: return L10n.settingsNotificationsAllowed
        case .off: return L10n.settingsNotificationsOff
        case .notAsked: return L10n.settingsNotificationsNotAsked
        }
    }

    var body: some View {
        AdaptiveStack(horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.xs) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.settingsNotifications)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                Text(statusText)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }
            .accessibilityElement(children: .combine)

            AdaptiveSpacer()

            // Kept out of the combined status so VoiceOver can reach it.
            switch permission {
            case .allowed:
                EmptyView()
            case .off:
                actionButton(L10n.settingsNotificationsOpenSettings) {
                    guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            case .notAsked:
                actionButton(L10n.settingsNotificationsTurnOn) {
                    Task {
                        let granted = await NotificationService.shared.requestAuthorization()
                        AnalyticsService.shared.capture(granted ? .notificationPermissionGranted : .notificationPermissionDenied)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .frame(minHeight: TouchTarget.minimum)
        // Coming back from the Settings app is when the answer changes.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await NotificationService.shared.checkAuthorizationStatus()
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.accent)
                .tracking(1)
                .textCase(.uppercase)
                .minimumTouchTarget()
        }
        .buttonStyle(.plain)
    }
}
