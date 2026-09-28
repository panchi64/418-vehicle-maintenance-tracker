import AppIntents
import SwiftUI
import UserNotifications

@main
struct BiomboApp: App {
    /// Launch with `-crisis` to see the same island in crisis mode (or flip it
    /// in Ajustes › Muestra), `-offline` or `-weakSignal` for the connection,
    /// `-sampleWatches` to start with the sample watch list, `-sampleOutbox`
    /// to refill the outbox with its sample reports, `-sampleContributions`
    /// to go back to the sample device's reports and votes,
    /// `-skipOnboarding` or `-onboarding` to skip or replay the first run, and
    /// `-vantage 18.3755,-66.1190` to stand somewhere else (next to Puma Los
    /// Filtros, there), since confirming and reporting are for people nearby.
    private let arguments = ProcessInfo.processInfo.arguments
    /// Saves the watch list, outbox and Tu aporte as they change, even when
    /// Siri changed them with no window open.
    private let persistence: DevicePersistence
    /// SAMPLE: the pretend owner call; nothing leaves the device.
    private let ownerVerifier = SampleOwnerVerifier()

    @State private var store: SnapshotStore
    @State private var switches: SampleSwitches
    @State private var device: DeviceStore
    @State private var watches: WatchStore
    @State private var contributions: ContributionStore
    @State private var router: AppRouter
    @AppStorage(PriceUnit.storageKey) private var storedUnit: PriceUnit?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let switches = SampleSwitches(isCrisis: arguments.contains("-crisis"))
        // The outbox survives relaunches; first launch (or `-sampleOutbox`) starts with the sample queue.
        let outbox = arguments.contains("-sampleOutbox") ? nil : DeviceStorage.outbox(.standard).load()
        let device = DeviceStore(
            connection: LaunchArguments.connection(in: arguments), outbox: outbox ?? SampleData.outbox, offlineClock: SampleData.offlineNow
        )
        let stored = DeviceStorage.watchedPlaces(.standard).load()
        let seeded = arguments.contains("-sampleWatches") ? SampleData.watchedPlaces : nil
        let watches = WatchStore(places: seeded ?? stored ?? [])
        // Votes, history and seals survive relaunches; first launch (or
        // `-sampleContributions`) starts with the sample device's.
        let ledger = arguments.contains("-sampleContributions") ? nil : DeviceStorage.contributions(.standard).load()
        let contributions = ledger.map { ContributionStore($0) } ?? ContributionStore(
            history: SampleData.myReports, votes: SampleData.myVotes, ownedPlaces: SampleData.ownedPlaces
        )
        let store = SnapshotStore()
        let router = AppRouter()
        let vantage = LaunchArguments.vantage(in: arguments)
        // Intents run in this process and read these same stores.
        IntentContext(
            snapshots: store, device: device, watches: watches, contributions: contributions,
            provider: { Self.provider(switches, vantage: vantage) }
        ).register()
        LaunchArguments.applyOnboarding(arguments, to: .standard)
        persistence = DevicePersistence(
            watches: watches, device: device, contributions: contributions, defaults: .standard,
            savesWatches: seeded == nil, onWatchesChange: { BiomboShortcuts.updateAppShortcutParameters() }
        )

        _switches = State(initialValue: switches)
        _device = State(initialValue: device)
        _watches = State(initialValue: watches)
        _contributions = State(initialValue: contributions)
        _store = State(initialValue: store)
        _router = State(initialValue: router)
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .environment(switches)
                .environment(device)
                .environment(watches)
                .environment(contributions)
                .environment(router)
                .environment(\.ownerVerifier, ownerVerifier)
                .environment(\.theme, store.theme)
                .environment(\.priceUnit, PriceUnit.current(stored: storedUnit))
                .tint(store.theme.accent)
                .task(id: switches.isCrisis) { await load() }
                // A Control's tap waits in the App Group until the app takes it.
                .onReceive(NotificationCenter.default.publisher(for: PendingScreen.queuedNotification)) { _ in takePendingScreen() }
                .onChange(of: scenePhase, initial: true) { _, phase in
                    if phase == .active { takePendingScreen() }
                }
        }
    }

    /// Sample data until the backend exists; swap the provider, not the UI.
    private static func provider(_ switches: SampleSwitches, vantage: GeoPoint?) -> any PlacesProviding {
        SamplePlacesProvider(crisis: switches.isCrisis, vantage: vantage)
    }

    private func load() async {
        do {
            store.apply(try await Self.provider(switches, vantage: LaunchArguments.vantage(in: arguments)).snapshot())
        } catch {
            store.markFailed()
        }
    }

    private func takePendingScreen() {
        if let screen = PendingScreen.take(from: SharedContainer.defaults) {
            router.open(AppRoute(screen))
        }
    }
}
