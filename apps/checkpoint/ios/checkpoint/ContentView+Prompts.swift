//
//  ContentView+Prompts.swift
//  checkpoint
//
//  The two things the app asks for on its own initiative — permission to send
//  reminders, and a tip — and the timing rules that keep them out of the way:
//  never during onboarding, never over a sheet or form, never over each other.
//

import SwiftUI
import SwiftData

extension ContentView {

    // MARK: - Notification Permission

    /// Offer the reminders pre-prompt if `NotificationAskPolicy` says it's
    /// time. Runs when a sheet that creates services closes (a logged or
    /// scheduled service, a completion, a starter schedule) — the moment a
    /// reminder has something to be about — and never over a sheet.
    func considerNotificationPrePrompt() {
        guard onboardingState.currentPhase == .completed, appState.activeSheet == nil else { return }
        Task {
            await NotificationService.shared.checkAuthorizationStatus()
            let policy = NotificationAskPolicy(
                permission: NotificationService.shared.permission,
                hasCompletedOnboarding: onboardingState.currentPhase == .completed,
                serviceCount: (try? modelContext.fetchCount(FetchDescriptor<Service>())) ?? 0,
                lastDeclinedAt: NotificationPrePromptStore.lastDeclinedAt,
                askedThisSession: NotificationPrePromptStore.askedThisSession
            )
            // Re-check the sheet: one may have started presenting while the
            // settings read was in flight.
            guard policy.shouldAsk(), appState.activeSheet == nil else { return }
            NotificationPrePromptStore.recordShown()
            showNotificationPrePrompt = true
        }
    }

    /// The pre-prompt's answer. Only "Allow" reaches the system prompt, so a
    /// reflexive tap on "Not Now" never becomes a permanent "Don't Allow".
    func answerNotificationPrePrompt(allow: Bool) {
        guard allow else {
            NotificationPrePromptStore.recordDeclined()
            return
        }
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            AnalyticsService.shared.capture(granted ? .notificationPermissionGranted : .notificationPermissionDenied)
            guard granted else { return }
            // Reminders scheduled before permission existed never reached
            // the system; queue them now.
            for vehicle in vehicles {
                NotificationService.shared.rescheduleNotifications(for: vehicle)
                if vehicle.hasMarbeteExpiration {
                    NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
                }
            }
            schedulePeriodicNotifications()
        }
    }

    // MARK: - Tip Prompt

    /// Presents the tip modal a beat after AppState queues it. The delay and
    /// presentation are view-layer effects; AppState only flips the flag.
    ///
    /// Never during onboarding, and never over the notification pre-prompt:
    /// a dropped prompt isn't recorded as shown, so the next qualifying
    /// action queues it again. It never covers a form either —
    /// `presentWhenIdle` waits for the open sheet to close.
    func presentQueuedTipPrompt() {
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard appState.tipPromptQueued else { return }
            appState.tipPromptQueued = false
            guard onboardingState.currentPhase == .completed, !showNotificationPrePrompt else { return }
            // Waits for any sheet the user is in rather than closing it.
            appState.presentWhenIdle(.tipModal)
            PurchaseSettings.shared.recordTipPromptShown()
            AnalyticsService.shared.capture(.tipModalShown(
                actionCount: PurchaseSettings.shared.completedActionCount,
                dismissCount: PurchaseSettings.shared.tipPromptDismissCount
            ))
        }
    }
}
