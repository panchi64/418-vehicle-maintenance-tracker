import Foundation

/// SAMPLE DATA — this device's own history for Tu aporte: reports "made"
/// since March with invented outcomes and reach, three past votes, and the
/// business this device verified. Invented, like everything in SampleData.
nonisolated extension SampleData {
    nonisolated static let myReports: [MyReport] = [
        mine(700, .flooded, ID.pr52Caguas, "PR-52, km 14", daysAgo: 1, .confirmed, helped: 112),
        mine(701, .noPower, ID.bairoa, "Bairoa, Caguas", daysAgo: 2, .confirmed, helped: 38),
        mine(702, .queue, ID.gulfBairoa, "Gulf Bairoa", daysAgo: 3, .waiting, helped: 0),
        mine(703, .hasGas, ID.gulfBairoa, "Gulf Bairoa", daysAgo: 4, .confirmed, helped: 24),
        mine(704, .price, ID.pumaLosFiltros, "Puma Los Filtros", daysAgo: 6, .confirmed, helped: 17),
        mine(705, .waterBack, ID.rioPiedras, "Río Piedras, San Juan", daysAgo: 12, .confirmed, helped: 9),
        mine(706, .chargerWorks, ID.chargerPlazaAmericas, "Cargador Plaza Las Américas", daysAgo: 20, .confirmed, helped: 6),
        mine(707, .price, ID.totalSanturce, "Total Santurce", daysAgo: 30, .removed(.mismatch), helped: 0),
        mine(708, .noSignal, ID.rioPiedras, "Río Piedras, San Juan", daysAgo: 45, .confirmed, helped: 14),
        mine(709, .price, ID.shellRioPiedras, "Shell Río Piedras", daysAgo: 60, .confirmed, helped: 11),
        mine(710, .businessOpen, ID.farmaciaDelPueblo, "Farmacia del Pueblo", daysAgo: 75, .confirmed, helped: 5),
        mine(711, .noPower, ID.miradero, "Miradero, Mayagüez", daysAgo: 90, .confirmed, helped: 41),
        mine(712, .landslide, ID.pr156Comerio, "PR-156, km 31", daysAgo: 120, .confirmed, helped: 30),
        mine(713, .price, ID.pumaCayey, "Puma Cayey", daysAgo: 150, .confirmed, helped: 8),
        mine(714, .lowPressure, ID.miradero, "Miradero, Mayagüez", daysAgo: 180, .confirmed, helped: 3),
    ]

    /// Past votes that matched how their reports were resolved. Their
    /// targets are long gone from the map, so nothing here recounts them.
    nonisolated static let myVotes: [MyVote] = [
        MyVote(target: .area("outage.power.caguas-2026-08"), agrees: true, castAt: now.addingTimeInterval(-.days(33)), matchedResolution: true),
        MyVote(target: .area("outage.water.san-juan-2026-07"), agrees: false, castAt: now.addingTimeInterval(-.days(64)), matchedResolution: true),
        MyVote(target: .area("outage.power.mayaguez-2026-06"), agrees: true, castAt: now.addingTimeInterval(-.days(95)), matchedResolution: true),
    ]

    /// This device verified Panadería La Ceiba as its owner.
    nonisolated static let ownedPlaces: [Place.ID: Date] = [
        ID.panaderiaLaCeiba: now.addingTimeInterval(.days(200)),
    ]

    private static func mine(
        _ number: Int, _ kind: ReportKind, _ placeID: Place.ID, _ placeName: String,
        daysAgo: Double, _ outcome: ReportOutcome, helped: Int
    ) -> MyReport {
        let report = Report(id: fixtureID(number), kind: kind, placeID: placeID, capturedAt: now.addingTimeInterval(-.days(daysAgo)))
        return MyReport(report: report, outcome: outcome, helped: helped, placeName: placeName)
    }
}
