//
//  PendingWidgetRoute.swift
//  CheckpointWidget
//
//  Widget or Control tap → a screen in the app, without a URL scheme.
//
//  The app declares no `CFBundleURLTypes` and no `onOpenURL` (see the
//  Security Posture in apps/checkpoint/ios/CLAUDE.md), so `widgetURL`/`Link`
//  are off the table. Instead:
//
//    - a widget row is a `Button(intent:)` running `OpenServiceIntent`,
//      whose `.foreground` mode launches the app and runs `perform()` there;
//    - a Control (Control Center, Lock Screen, Action button) is a
//      `ControlWidgetButton` running `OpenCheckpointScreenIntent`, an
//      `OpenIntent` — Apple's way to open the app from a control, which
//      requires the intent in both the app and the extension.
//
//  Either `perform()` stores a typed route in App Group defaults — the same
//  bridge `PendingWidgetCompletion` uses — and posts `widgetRouteQueued`;
//  the app takes the route on that post or on its next activation,
//  whichever lands first, and moves it into the app's one route store
//  (`PendingRouteStore`, State/PendingRoute.swift), which notifications and
//  intents feed too.
//
//  Compiled into BOTH the app and widget targets (SharedEntities group): the
//  system must find the intent types in the app to run them there.
//

import AppIntents
import Foundation

/// `nonisolated` so the same file means the same thing in the app (default
/// MainActor isolation) and the widget (no default isolation).
nonisolated struct PendingWidgetRoute: Codable, Equatable, Sendable {
    enum Destination: Codable, Equatable, Sendable {
        /// A widget row: one service's detail.
        case service(vehicleID: UUID, serviceID: UUID)
        /// A Control: a screen, on the vehicle the app is showing.
        case screen(CheckpointScreen)
    }

    let destination: Destination
    let createdAt: Date

    /// A route older than this is a tap the app never consumed (e.g. the launch
    /// failed); acting on it later would hijack an unrelated launch.
    nonisolated static let ttl: TimeInterval = 5 * 60

    /// Posted in the app process after an intent stores a route.
    nonisolated static let queuedNotification = Notification.Name("checkpoint.widgetRouteQueued")

    /// Store `route`, replacing any earlier one — only the latest tap matters.
    static func save(_ route: PendingWidgetRoute) {
        guard let defaults = WidgetAppGroup.defaults(),
              let data = try? JSONEncoder().encode(route) else { return }
        defaults.set(data, forKey: WidgetAppGroup.pendingWidgetRouteKey)
    }

    /// Store a service route from raw intent parameters. They are untrusted
    /// input: only well-formed UUIDs become a route. Returns whether one was
    /// stored.
    @discardableResult
    static func queue(serviceID: String, vehicleID: String, now: Date = Date()) -> Bool {
        guard let service = UUID(uuidString: serviceID),
              let vehicle = UUID(uuidString: vehicleID) else { return false }
        save(PendingWidgetRoute(destination: .service(vehicleID: vehicle, serviceID: service), createdAt: now))
        return true
    }

    /// Store a Control's screen route.
    static func queue(_ screen: CheckpointScreen, now: Date = Date()) {
        save(PendingWidgetRoute(destination: .screen(screen), createdAt: now))
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

    /// Tell a running app a route is waiting. Main actor so the app's
    /// `.onReceive` observer runs on the main thread.
    @MainActor
    static func announce() {
        NotificationCenter.default.post(name: queuedNotification, object: nil)
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

    @MainActor
    func perform() async throws -> some IntentResult {
        if PendingWidgetRoute.queue(serviceID: serviceID, vehicleID: vehicleID) {
            PendingWidgetRoute.announce()
        }
        return .result()
    }
}

// MARK: - Controls

/// The screens a Control opens, on the vehicle the app is showing. Raw
/// values are persisted in routes and saved shortcuts — never rename one.
nonisolated enum CheckpointScreen: String, Codable, Sendable, CaseIterable, AppEnum {
    case updateMileage
    case scanReceipt
    case logService

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Checkpoint Screen" }

    static var caseDisplayRepresentations: [CheckpointScreen: DisplayRepresentation] {
        [
            .updateMileage: DisplayRepresentation(title: "Update Mileage", image: .init(systemName: "gauge.with.dots.needle.67percent")),
            .scanReceipt: DisplayRepresentation(title: "Scan Receipt", image: .init(systemName: "doc.text.viewfinder")),
            .logService: DisplayRepresentation(title: "Log Service", image: .init(systemName: "square.and.pencil")),
        ]
    }
}

/// Opens the app on one of `CheckpointScreen`'s screens. The Controls'
/// action; also a Shortcuts action ("Open Checkpoint to Scan Receipt"), so
/// the Action button can run it through a shortcut too.
struct OpenCheckpointScreenIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open in Checkpoint"
    static let description = IntentDescription("Open Checkpoint to update the mileage, scan a receipt, or log a service on the vehicle it's showing")

    @Parameter(title: "Screen")
    var target: CheckpointScreen

    init() {}

    init(target: CheckpointScreen) {
        self.target = target
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingWidgetRoute.queue(target)
        PendingWidgetRoute.announce()
        return .result()
    }
}
