import SwiftUI
import UIKit
import UserNotifications

/// Ajustes › Avisos (PRODUCT.md §9): whether Biombo may notify, one verb to
/// change that, and what a watch will and won't send. Permission is asked
/// here or on the first watch, never at launch.
struct NotificationSettingsSection: View {
    @State private var access: NotificationAccess?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale

    var body: some View {
        Section {
            if let access {
                Label {
                    Text(access.status)
                        .foregroundStyle(Color(.ink))
                } icon: {
                    Image(systemName: access.symbol).accessibilityHidden(true)
                }
                switch access {
                case .notAsked:
                    Button { Task { await ask() } } label: {
                        Text("Permitir avisos", comment: "Settings: ask for notification permission")
                    }
                    .frame(minHeight: Size.target)
                case .off:
                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                    } label: {
                        Text("Abrir Ajustes", comment: "Settings: open the system notification settings")
                    }
                    .frame(minHeight: Size.target)
                case .allowed:
                    EmptyView()
                }
            }
        } header: {
            Text("Avisos", comment: "Settings section: notifications")
        } footer: {
            Text(footer)
        }
        .task(id: scenePhase) {
            if scenePhase == .active { await refresh() }
        }
    }

    /// Quiet hours in the device's own zone, so family off-island isn't woken.
    private var footer: LocalizedStringResource {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: QuietHours.start, minute: 0, second: 0, of: .now) ?? .now
        let end = calendar.date(bySettingHour: QuietHours.end, minute: 0, second: 0, of: .now) ?? .now
        let style = Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)
        return LocalizedStringResource(
            "Solo cambios confirmados en los lugares que vigilas, nunca precios. De \(start.formatted(style)) a \(end.formatted(style)) solo llegan los avisos oficiales urgentes.",
            comment: "Settings footer: what notifications send, and the quiet hours (start and end clock times)"
        )
    }

    private func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        access = NotificationAccess(settings.authorizationStatus)
    }

    private func ask() async {
        // No .badge and no Critical Alerts (§9).
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        await refresh()
    }
}

/// Whether Biombo may notify, in the three states the section speaks to.
enum NotificationAccess: Hashable {
    case notAsked
    case allowed
    case off

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notAsked
        case .authorized, .provisional, .ephemeral: self = .allowed
        case .denied: self = .off
        @unknown default: self = .off
        }
    }

    var status: LocalizedStringResource {
        switch self {
        case .notAsked: LocalizedStringResource("Todavía no has permitido avisos.", comment: "Settings: notifications were never asked for")
        case .allowed: LocalizedStringResource("Los avisos están permitidos.", comment: "Settings: notifications are allowed")
        case .off: LocalizedStringResource("Los avisos están apagados para Biombo.", comment: "Settings: notifications are turned off")
        }
    }

    var symbol: String {
        switch self {
        case .notAsked: "bell"
        case .allowed: "bell.badge"
        case .off: "bell.slash"
        }
    }
}
