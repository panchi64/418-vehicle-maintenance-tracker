//
//  PendingWidgetRoute.swift
//  CheckpointWidget
//
//  Widget tap → the tapped service's detail in the app, without a URL scheme.
//
//  The app declares no `CFBundleURLTypes` and no `onOpenURL` (see the
//  Security Posture in apps/checkpoint/ios/CLAUDE.md), so `widgetURL`/`Link`
//  are off the table. Instead a widget row is a `Button(intent:)` running
//  `OpenServiceIntent`, whose `.foreground` mode launches the app and runs
//  `perform()` there. `perform()` stores a typed route in App Group defaults —
//  the same bridge `PendingWidgetCompletion` uses — and posts
//  `widgetRouteQueued`; the app takes the route on that post or on its next
//  activation, whichever lands first, and hands it to the notification-route
//  navigation it already has.
//
//  Compiled into BOTH the app and widget targets (SharedEntities group): the
//  system must find the intent type in the app to run it there.
//

import AppIntents
import Foundation

/// `nonisolated` so the same file means the same thing in the app (default
/// MainActor isolation) and the widget (no default isolation).
nonisolated struct PendingWidgetRoute: Codable, Equatable, Sendable {
    let vehicleID: UUID
    let serviceID: UUID
    let createdAt: Date

    /// A route older than this is a tap the app never consumed (e.g. the launch
    /// failed); acting on it later would hijack an unrelated launch.
    nonisolated static let ttl: TimeInterval = 5 * 60

    /// Posted in the app process after `OpenServiceIntent` stores a route.
    nonisolated static let queuedNotification = Notification.Name("checkpoint.widgetRouteQueued")

    /// Store `route`, replacing any earlier one — only the latest tap matters.
    static func save(_ route: PendingWidgetRoute) {
        guard let defaults = WidgetAppGroup.defaults(),
              let data = try? JSONEncoder().encode(route) else { return }
        defaults.set(data, forKey: WidgetAppGroup.pendingWidgetRouteKey)
    }

    /// Remove and return the stored route, or nil when there is none or it has
    /// expired. Consuming clears it so one tap navigates once.
    static func take(now: Date = Date()) -> PendingWidgetRoute? {
        guard let defaults = WidgetAppGroup.defaults(),
              let data = defaults.data(forKey: WidgetAppGroup.pendingWidgetRouteKey) else { return nil }
        defaults.removeObject(forKey: WidgetAppGroup.pendingWidgetRouteKey)
        guard let route = try? JSONDecoder().decode(PendingWidgetRoute.self, from: data),
              now.timeIntervalSince(route.createdAt) < ttl else { return nil }
        return route
    }
}

/// Opens the app on one service's detail. Used by widget rows; not offered to
/// Shortcuts or Siri since its parameters are raw identifiers.
struct OpenServiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Service"
    static let description = IntentDescription("Open a service in Checkpoint from the widget")
    static let supportedModes: IntentModes = .foreground
    static let isDiscoverable = false

    @Parameter(title: "Service ID")
    var serviceID: String

    @Parameter(title: "Vehicle ID")
    var vehicleID: String

    init() {
        self.serviceID = ""
        self.vehicleID = ""
    }

    init(serviceID: String, vehicleID: String) {
        self.serviceID = serviceID
        self.vehicleID = vehicleID
    }

    /// Main actor so the app's `.onReceive` observer runs on the main thread.
    @MainActor
    func perform() async throws -> some IntentResult {
        // Parameters are untrusted input: only well-formed UUIDs become a route.
        if let service = UUID(uuidString: serviceID), let vehicle = UUID(uuidString: vehicleID) {
            PendingWidgetRoute.save(PendingWidgetRoute(vehicleID: vehicle, serviceID: service, createdAt: Date()))
            NotificationCenter.default.post(name: PendingWidgetRoute.queuedNotification, object: nil)
        }
        return .result()
    }
}
