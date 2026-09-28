import CoreLocation

/// Asks for When In Use location once, after the first run has said why
/// (§13: When In Use only, never Always). `request()` returns once the
/// person has answered, or at once if they already did.
final class LocationPermission: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var waiting: CheckedContinuation<Void, Never>?

    func request() async {
        guard manager.authorizationStatus == .notDetermined, waiting == nil else { return }
        manager.delegate = self
        await withCheckedContinuation { continuation in
            waiting = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    /// Also called as soon as the delegate is set, with the status still
    /// undetermined; only an answer ends the wait.
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.answered(status) }
    }

    private func answered(_ status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }
        waiting?.resume()
        waiting = nil
    }
}
