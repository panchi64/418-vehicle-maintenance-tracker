import Foundation
import Observation

/// Saves what the device keeps whenever it changes, from launch on: the
/// watch list, the outbox and Tu aporte (PRODUCT.md §9, §4.6, §10). It
/// observes the stores themselves rather than a view, so what Siri changes
/// while the app runs in the background with no window (a voice report, a
/// new watch) is kept too. The stores stay pure; saving happens here.
final class DevicePersistence {
    private let tasks: [Task<Void, Never>]

    /// - Parameters:
    ///   - savesWatches: false while trying the sample watch list, which
    ///     never overwrites the real one.
    ///   - onWatchesChange: after the watch list changes (Siri's place names).
    init(
        watches: WatchStore,
        device: DeviceStore,
        contributions: ContributionStore,
        defaults: UserDefaults,
        savesWatches: Bool,
        onWatchesChange: @escaping @MainActor () -> Void
    ) {
        let watchStorage = DeviceStorage.watchedPlaces(defaults)
        let outboxStorage = DeviceStorage.outbox(defaults)
        let contributionStorage = DeviceStorage.contributions(defaults)
        tasks = [
            Self.keep({ @MainActor in watches.places }) { places in
                if savesWatches { watchStorage.save(places) }
                onWatchesChange()
            },
            Self.keep({ @MainActor in device.outbox }) { outboxStorage.save($0) },
            Self.keep({ @MainActor in contributions.ledger }) { contributionStorage.save($0) }
        ]
    }

    deinit {
        tasks.forEach { $0.cancel() }
    }

    /// Hands every value `read` takes on to `save`, the current one first.
    private static func keep<Value: Sendable>(
        _ read: @escaping @MainActor @Sendable () -> Value,
        save: @escaping @MainActor (Value) -> Void
    ) -> Task<Void, Never> {
        Task { @MainActor in
            for await value in Observations(read) {
                save(value)
            }
        }
    }
}
