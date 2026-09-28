import Foundation

/// Everything the map and sheets read, as one consistent snapshot.
/// Mirrors the crisis read path (PRODUCT.md §8): answers come from snapshots.
nonisolated struct PlacesSnapshot: Hashable, Sendable {
    var places: [Place]
    var reports: [Report]
    var outageAreas: [OutageArea]
    var notices: [OfficialNotice]
    var dacoReferences: [DacoReference]
    /// Reports past the show-older horizon, kept only for trends (§4.4, §6.1).
    var history: [Report] = []
    /// 90-day charger records (§6.7).
    var chargerTallies: [ChargerTally] = []
    var crisis: CrisisState
    /// The clock freshness is judged against: when the snapshot was cut, or
    /// the device's later clock once `aged(to:)`.
    var generatedAt: Date
    /// Where "cerca" is measured from. The sample provider pins it until
    /// device location lands; the UI never reads it from anywhere else.
    var vantage: GeoPoint

    /// The same data judged at a later clock: offline, the cached snapshot
    /// ages under the same freshness rules as ever, so nothing reads as
    /// current past its window (§4.6).
    func aged(to now: Date) -> PlacesSnapshot {
        var copy = self
        copy.generatedAt = max(now, generatedAt)
        return copy
    }
}

/// The seam between the UI and wherever places come from. Today only
/// `SamplePlacesProvider`; the backend client lands behind the same protocol.
nonisolated protocol PlacesProviding: Sendable {
    func snapshot() async throws -> PlacesSnapshot
}
