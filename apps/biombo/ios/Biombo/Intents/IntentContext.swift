import AppIntents
import Foundation

/// The one data path for App Intents: the app's own stores, registered with
/// `AppDependencyManager` at launch and read with `@Dependency`. Intents run
/// in the app process, so what Siri says is what the map shows, and what
/// Siri records lands where the UI records it. The widgets run out of
/// process and read the App Group snapshot instead.
final class IntentContext {
    let snapshots: SnapshotStore
    let device: DeviceStore
    let watches: WatchStore
    let contributions: ContributionStore
    /// Where places come from when the system launched the app just for an
    /// intent and nothing is loaded yet.
    private let provider: () -> any PlacesProviding

    init(
        snapshots: SnapshotStore,
        device: DeviceStore,
        watches: WatchStore,
        contributions: ContributionStore,
        provider: @escaping () -> any PlacesProviding
    ) {
        self.snapshots = snapshots
        self.device = device
        self.watches = watches
        self.contributions = contributions
        self.provider = provider
    }

    /// Makes this the context intents read. Registering replaces any earlier one.
    func register() {
        AppDependencyManager.shared.add(dependency: self)
    }

    /// The snapshot as the app shows it: judged at the device's clock, with
    /// this device's own reports and votes folded in.
    func snapshot() async -> PlacesSnapshot? {
        if snapshots.snapshot == nil, let loaded = try? await provider().snapshot() {
            snapshots.apply(loaded)
        }
        guard let snapshot = snapshots.snapshot else { return nil }
        return contributions.shown(snapshot, at: device.state(lastSyncedAt: snapshot.generatedAt))
    }

    /// Every answer on the island, as the map derives them.
    func digest() async -> HomeDigest? {
        await snapshot().map(Self.digest(of:))
    }

    /// What every answer says when no places could be loaded.
    static func placesFailed(locale: Locale) -> String {
        LocalizedStringResource("Biombo no pudo cargar los lugares.", comment: "Siri: places failed to load").string(in: locale)
    }

    static func digest(of snapshot: PlacesSnapshot) -> HomeDigest {
        HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: Set(Layer.allCases))
    }

    /// A voice report joins the outbox and Tu aporte; the app files it like
    /// any queued report as soon as it is open with a network (§4.6).
    func queue(_ voice: VoiceReport) {
        device.enqueue(voice.queued)
        contributions.recordUnpublished(voice.report, placeName: voice.target.place.displayName)
    }
}
