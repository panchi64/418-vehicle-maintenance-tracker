import Foundation

/// A value kept on the device only, as JSON in the app's defaults: watched
/// places (PRODUCT.md §9 "Privacy"), the outbox (§4.6) and this device's
/// contributions (§10, §13). The app loads on
/// launch and saves on every change; stores never touch storage themselves.
struct DeviceStorage<Value: Codable> {
    let key: String
    var defaults: UserDefaults

    /// nil when nothing was ever saved, so first launch can tell itself apart
    /// from a user who emptied the list.
    func load() -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}

extension DeviceStorage where Value == [WatchedPlace] {
    static func watchedPlaces(_ defaults: UserDefaults) -> Self {
        Self(key: "watchedPlaces", defaults: defaults)
    }
}

extension DeviceStorage where Value == Outbox {
    static func outbox(_ defaults: UserDefaults) -> Self {
        Self(key: "outbox", defaults: defaults)
    }
}

extension DeviceStorage where Value == ContributionLedger {
    /// Reports, votes, the owner's seal and any claim (§4.3 one vote per
    /// reporter holds across launches).
    static func contributions(_ defaults: UserDefaults) -> Self {
        Self(key: "contributions", defaults: defaults)
    }
}
