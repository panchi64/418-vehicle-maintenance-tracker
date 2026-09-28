import Foundation

/// SAMPLE DATA — invented fixtures for building the UI with no backend.
///
/// Places, prices, reports and notices are realistic but not real: no report
/// here was made by anyone, and no agency issued these notices. Every value is
/// pinned to `SampleData.now`, so previews and tests are deterministic.
nonisolated enum SampleData {
    /// Sunday 27 September 2026, 5:30 p.m. in Puerto Rico (AST, UTC−4).
    nonisolated static let now: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 27
        components.hour = 17
        components.minute = 30
        components.timeZone = timeZone
        return Calendar(identifier: .gregorian).date(from: components)!
    }()

    nonisolated static let timeZone = PuertoRico.timeZone

    /// Where "Cerca de ti" is measured from until real location lands: Guaynabo,
    /// a short drive from Frailes, Santurce and Río Piedras, and clear of the
    /// Frailes pins so the dot stays visible at the launch camera.
    nonisolated static let vantage = GeoPoint(18.4020, -66.1080)

    /// An ordinary day, or the same island with crisis mode on (§8).
    /// `vantage` stands in for the device's location; the launch argument
    /// `-vantage lat,lon` moves it, e.g. next to a station to try confirming.
    static func snapshot(crisis: Bool = false, vantage: GeoPoint = SampleData.vantage) -> PlacesSnapshot {
        PlacesSnapshot(
            places: crisis ? places + crisisPlaces : places,
            reports: crisis ? reports + crisisReports : reports,
            outageAreas: crisis ? crisisOutageAreas : outageAreas,
            notices: crisis ? notices + crisisNotices : notices,
            dacoReferences: dacoReferences,
            history: history,
            chargerTallies: chargerTallies,
            crisis: crisis ? crisisState : .ordinary,
            generatedAt: now,
            vantage: vantage
        )
    }

    nonisolated static let crisisState = CrisisState(
        triggers: [.nwsWarning, .communityPowerAreas],
        since: now.addingTimeInterval(-.hours(6))
    )

    /// A time `minutes` before `now`.
    static func ago(minutes: Double) -> Date {
        now.addingTimeInterval(-.minutes(minutes))
    }

    /// Stable ids so fixtures compare equal across runs.
    static func fixtureID(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", number))!
    }
}

/// Serves `SampleData` through the same seam the backend client will use.
nonisolated struct SamplePlacesProvider: PlacesProviding {
    var crisis = false
    var vantage: GeoPoint?

    func snapshot() async throws -> PlacesSnapshot {
        SampleData.snapshot(crisis: crisis, vantage: vantage ?? SampleData.vantage)
    }
}
