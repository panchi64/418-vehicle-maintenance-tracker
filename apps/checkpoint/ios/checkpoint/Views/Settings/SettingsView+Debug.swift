//
//  SettingsView+Debug.swift
//  checkpoint
//
//  Developer-only rows: English, never localized, compiled out of release.
//

#if DEBUG
import SwiftUI
import UserNotifications

extension SettingsView {
    var debugSection: some View {
        SettingsGroup(title: "Debug") {
            SettingsActionRow(
                title: "Replay Onboarding",
                systemImage: "arrow.counterclockwise",
                iconColor: Theme.textTertiary
            ) {
                onboardingState?.replayOnboarding()
                dismiss()
            }

            SettingsRowDivider()

            SettingsActionRow(
                title: "Show Tip Prompt",
                systemImage: "heart",
                iconColor: Theme.textTertiary
            ) {
                showTipModal = true
            }
            .sheet(isPresented: $showTipModal) {
                TipModalView()
                    .environment(appState)
            }

            SettingsRowDivider()

            SettingsActionRow(
                title: "Fire Test Notification (3s)",
                systemImage: "bell",
                iconColor: Theme.textTertiary
            ) {
                Task { await Self.fireTestNotification() }
            }
        }
    }

    private static func fireTestNotification() async {
        let messages: [(title: String, body: String)] = [
            ("Odometer Sync Requested", "It's been a while. How far have we gone?"),
            ("Marbete Status: 30 Days", "Would prefer not to be impounded."),
            ("Marbete Status: 7 Days", "Starting to worry about that marbete."),
            ("Marbete Status: URGENT", "Expires tomorrow. Legally speaking."),
            ("Oil Change Due in 1 Week", "The oil is aging. So are we all."),
            ("Tire Rotation Reminder", "The tires asked me to ask you."),
            ("Brake Inspection Due", "Stopping is optional. Until it isn't."),
            ("Coolant Flush Due Soon", "Running a little warm. Thought you should know."),
            ("2025 Expense Report", "You spent a lot last year. You're welcome."),
            ("Marbete Status: 60 Days", "Requesting registration renewal. No rush. Yet."),
        ]
        guard let pick = messages.randomElement() else { return }
        let content = UNMutableNotificationContent()
        content.title = pick.title
        content.body = pick.body
        content.sound = .default
        content.categoryIdentifier = NotificationService.serviceDueCategoryID
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "debug-test-notification", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
#endif
