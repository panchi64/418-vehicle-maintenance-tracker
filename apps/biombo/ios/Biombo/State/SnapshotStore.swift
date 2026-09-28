import Observation

/// Holds the latest places snapshot. Pure state: the view layer fetches from a
/// `PlacesProviding` and hands the result in.
@Observable
final class SnapshotStore {
    enum Phase: Equatable {
        case loading
        case loaded(PlacesSnapshot)
        case failed
    }

    private(set) var phase: Phase = .loading

    var snapshot: PlacesSnapshot? {
        if case .loaded(let snapshot) = phase { snapshot } else { nil }
    }

    /// Crisis mode follows the snapshot; nothing else decides it.
    var theme: Theme {
        Theme(isCrisis: snapshot?.crisis.isActive ?? false)
    }

    func apply(_ snapshot: PlacesSnapshot) {
        phase = .loaded(snapshot)
    }

    func markFailed() {
        phase = .failed
    }
}
