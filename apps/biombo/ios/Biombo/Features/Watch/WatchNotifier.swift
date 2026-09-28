import SwiftUI
import UserNotifications

/// Local notifications for watching (PRODUCT.md §9). Today only the preview
/// ("Ver cómo llega el aviso"): one notification scoped to the place, a few
/// seconds out. Real pushes come from the server once it exists.
enum WatchNotifier {
    enum Outcome {
        case scheduled
        /// The user said no, or turned notifications off in Settings.
        case notAllowed
    }

    /// Seconds before the preview arrives, so the user can leave the app to see it.
    static let previewDelay: TimeInterval = 4

    static func sendPreview(for place: WatchedPlace, locale: Locale) async -> Outcome {
        let center = UNUserNotificationCenter.current()
        // No .badge: nothing sets or clears the icon badge. No Critical Alerts (§9).
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return .notAllowed }
        let content = UNMutableNotificationContent()
        content.title = place.previewTitle.string(in: locale)
        content.body = place.previewBody.string(in: locale)
        content.threadIdentifier = place.id.uuidString
        content.interruptionLevel = .active
        let request = UNNotificationRequest(
            identifier: "watch-preview-\(place.id.uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: previewDelay, repeats: false)
        )
        do {
            try await center.add(request)
            return .scheduled
        } catch {
            return .notAllowed
        }
    }
}

/// Shows Biombo's notifications while the app is open too, so the preview
/// is seen wherever the user is.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    /// Touches no state, so the system can call it from any thread.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
