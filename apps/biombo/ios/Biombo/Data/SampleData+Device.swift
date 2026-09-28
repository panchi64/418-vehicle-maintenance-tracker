import Foundation

/// SAMPLE DATA — a device's own state: three watched places, as a family
/// off-island might set them up, and reports queued while offline. Invented.
nonisolated extension SampleData {
    nonisolated static let watchedPlaces: [WatchedPlace] = [
        WatchedPlace(
            id: fixtureID(500), name: "Casa de Mamá", location: GeoPoint(18.2200, -67.1415),
            municipio: "Mayagüez", barrio: "Miradero", placeID: ID.miradero
        ),
        WatchedPlace(
            id: fixtureID(501), name: "Apartamento de Tití", location: GeoPoint(18.2655, -66.7005),
            municipio: "Utuado", barrio: "Pueblo"
        ),
        WatchedPlace(
            id: fixtureID(502), name: "Casa de Abuela", location: GeoPoint(18.1100, -66.1700),
            municipio: "Cayey", barrio: "Montellano"
        ),
    ]

    /// Offline, the device's clock runs 40 minutes past the last sync.
    nonisolated static let offlineNow = now.addingTimeInterval(.minutes(40))

    /// Two reports waiting for signal, and one from yesterday that asks first.
    /// All were made before the last sync, so no clock shows them in the future.
    nonisolated static let outbox = Outbox(items: [
        QueuedReport(id: fixtureID(600), kind: .noPower, placeName: "Calle Betances, Guaynabo", capturedAt: now.addingTimeInterval(-.minutes(8))),
        QueuedReport(id: fixtureID(601), kind: .closed, placeName: "PR-20, Guaynabo", capturedAt: now.addingTimeInterval(-.minutes(3))),
        QueuedReport(id: fixtureID(602), kind: .noWater, placeName: "Frailes, Guaynabo", capturedAt: now.addingTimeInterval(-.hours(26))),
    ])
}
