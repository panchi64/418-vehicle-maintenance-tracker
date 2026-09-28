import AppIntents
import Foundation

/// Where a Control or widget opens the app. Raw values are saved by
/// Controls, widgets and shortcuts: never rename one.
nonisolated enum BiomboScreen: String, Codable, Sendable, CaseIterable, AppEnum {
    /// Quick Report, about where you stand.
    case report
    /// "No hay luz aquí": one tap, with Deshacer.
    case noPower
    /// "Volvió la luz": one tap, with Deshacer.
    case powerBack
    /// The watch list.
    case watchList

    // App Intents metadata is read at build time, so these stay plain literals.
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Pantalla de Biombo" }

    static var caseDisplayRepresentations: [BiomboScreen: DisplayRepresentation] {
        [
            .report: DisplayRepresentation(title: "Reportar", image: .init(systemName: "plus.bubble")),
            .noPower: DisplayRepresentation(title: "No hay luz aquí", image: .init(systemName: "bolt.slash.fill")),
            .powerBack: DisplayRepresentation(title: "Volvió la luz", image: .init(systemName: "bolt.fill")),
            .watchList: DisplayRepresentation(title: "Lugares que vigilas", image: .init(systemName: "eye"))
        ]
    }
}

/// A screen a Control or widget asked for, left in the App Group for the
/// app to take on its next activation or on `queuedNotification`, whichever
/// comes first. One tap opens once.
nonisolated struct PendingScreen: Codable, Equatable, Sendable {
    let screen: BiomboScreen
    let createdAt: Date

    static let storageKey = "pendingScreen"
    /// A tap the app never took (the launch failed) is dropped after this,
    /// so it can't hijack an unrelated launch later.
    static let ttl: TimeInterval = 5 * 60
    /// Posted in the app process once a screen is queued.
    static let queuedNotification = Notification.Name("com.418-studio.biombo.pendingScreen")

    static func queue(_ screen: BiomboScreen, in defaults: UserDefaults?, now: Date = Date()) {
        guard let data = try? JSONEncoder().encode(PendingScreen(screen: screen, createdAt: now)) else { return }
        defaults?.set(data, forKey: storageKey)
    }

    /// Removes and returns the waiting screen, unless it expired.
    static func take(from defaults: UserDefaults?, now: Date = Date()) -> BiomboScreen? {
        guard let defaults, let data = defaults.data(forKey: storageKey) else { return nil }
        defaults.removeObject(forKey: storageKey)
        guard let pending = try? JSONDecoder().decode(PendingScreen.self, from: data),
              now.timeIntervalSince(pending.createdAt) < ttl else { return nil }
        return pending.screen
    }
}

/// Opens Biombo on one of `BiomboScreen`'s screens: the Controls' action
/// (Control Center, Lock Screen, Action button). An `OpenIntent`, Apple's way
/// for a control to open its app, so it is in both the app and the extension.
/// Whether a Control can get a location fix without the app is unverified
/// (PRODUCT.md open decision 16), so it opens the app, which reports with
/// Deshacer where you stand.
struct OpenBiomboScreenIntent: OpenIntent {
    static let title: LocalizedStringResource = "Abrir en Biombo"
    static let description = IntentDescription("Abre Biombo para reportar donde estás o ver los lugares que vigilas.")

    @Parameter(title: "Pantalla")
    var target: BiomboScreen

    init() {}

    init(target: BiomboScreen) {
        self.target = target
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingScreen.queue(target, in: SharedContainer.defaults)
        NotificationCenter.default.post(name: PendingScreen.queuedNotification, object: nil)
        return .result()
    }
}
