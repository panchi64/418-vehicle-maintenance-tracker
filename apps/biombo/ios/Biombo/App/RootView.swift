import SwiftUI

/// Loads into home, after the three-step first run. Crisis mode and every
/// answer follow the snapshot. Offline, the snapshot on screen is the last
/// one fetched, judged at the device's clock so it ages under the usual
/// freshness rules (§4.6). What this device sent since is folded in, so its
/// reports and votes count under the same rules as everyone's.
struct RootView: View {
    let store: SnapshotStore

    @Environment(DeviceStore.self) private var device
    @Environment(ContributionStore.self) private var contributions
    @Environment(AppRouter.self) private var router
    @AppStorage(Preferences.hasOnboarded) private var hasOnboarded = false
    @AppStorage(LayerChoice.storageKey) private var layerChoice: LayerChoice?

    /// What the outbox replay waits on: the network coming back, or a
    /// report queued while online (a voice report).
    private struct ReplayTrigger: Hashable {
        let status: ConnectionStatus
        let pending: Int
    }

    var body: some View {
        switch store.phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.paper))
        // In crisis the outages come first: a new user goes straight to the
        // map, and meets the first run once the crisis is over.
        case .loaded(let snapshot) where !hasOnboarded && !snapshot.crisis.isActive:
            OnboardingView(onFinish: finishOnboarding)
        case .loaded(let snapshot):
            let connection = device.state(lastSyncedAt: snapshot.generatedAt)
            let shown = contributions.shown(snapshot, at: connection)
            let trigger = ReplayTrigger(status: connection.status, pending: device.outbox.pending(now: connection.now).count)
            HomeView(snapshot: shown, connection: connection, chosenLayers: layerChoice?.layers)
                .task(id: trigger) { await replayOutbox(connection, snapshot: shown) }
        case .failed:
            Text("No se pudieron cargar los lugares.", comment: "Loading places failed")
                .textRole(.body)
                .foregroundStyle(Color(.ink2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.paper))
        }
    }

    /// The chosen layers are drawn from now on; "Vigilar un lugar" opens its search on the map.
    /// A route asked for before the first run (a Control's tap) is dropped,
    /// so the map doesn't open on something the user no longer expects.
    private func finishOnboarding(_ result: OnboardingResult) {
        layerChoice = LayerChoice(result.layers)
        router.discard()
        if result.wantsToWatch { router.open(.watchAnother) }
        hasOnboarded = true
    }

    /// The network is back: after a jittered pause, what waited in the
    /// outbox goes out through the same doors as a fresh report (§4.2, §4.6).
    /// On sample data the send always succeeds, so there is no retry past
    /// the first try.
    private func replayOutbox(_ connection: ConnectionState, snapshot: PlacesSnapshot) async {
        guard !connection.queuesReports, !device.outbox.isEmpty else { return }
        try? await Task.sleep(for: .seconds(ReplaySchedule.delay(attempt: 0, jitter: .random(in: 0...1))))
        guard !Task.isCancelled else { return }
        let sender = ReportSender(contributions: contributions, device: device, snapshot: snapshot, areas: [], connection: connection)
        sender.replay(device.takeReplayable(now: connection.now))
    }
}

#Preview("Ordinary day") {
    let store = SnapshotStore()
    store.apply(SampleData.snapshot())
    return RootView(store: store)
        .environment(DeviceStore())
        .environment(WatchStore(places: SampleData.watchedPlaces))
        .environment(ContributionStore(history: SampleData.myReports, votes: SampleData.myVotes, ownedPlaces: SampleData.ownedPlaces))
        .environment(SampleSwitches())
        .environment(AppRouter())
}

#Preview("Crisis, offline") {
    let store = SnapshotStore()
    store.apply(SampleData.snapshot(crisis: true))
    return RootView(store: store)
        .environment(DeviceStore(connection: .offline, outbox: SampleData.outbox, offlineClock: SampleData.offlineNow))
        .environment(WatchStore(places: SampleData.watchedPlaces))
        .environment(ContributionStore(history: SampleData.myReports, votes: SampleData.myVotes, ownedPlaces: SampleData.ownedPlaces))
        .environment(SampleSwitches(isCrisis: true))
        .environment(AppRouter())
        .environment(\.theme, store.theme)
}
