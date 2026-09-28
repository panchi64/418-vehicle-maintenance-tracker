import Foundation

/// SAMPLE DATA — what the island adds in crisis mode: fuel and generator
/// availability around the Guaynabo vantage, and LUMA confirming the Caguas
/// outage with neighbours reporting past its outline. Nobody made these
/// reports and no agency issued these statements.
nonisolated extension SampleData {
    nonisolated enum CrisisID {
        static let farmaciaFrailes = "business.farmacia-frailes"
        static let colmadoSantaRosa = "business.colmado-santa-rosa"
    }

    /// Two places open on a generator near the vantage.
    nonisolated static let crisisPlaces: [Place] = [
        Place(
            id: CrisisID.farmaciaFrailes, kind: .business, name: "Farmacia Frailes", municipio: "Guaynabo", barrio: "Frailes",
            region: .metro, geometry: .point(GeoPoint(18.3805, -66.1150))
        ),
        Place(
            id: CrisisID.colmadoSantaRosa, kind: .business, name: "Colmado Santa Rosa", municipio: "Guaynabo", barrio: "Santa Rosa",
            region: .metro, geometry: .point(GeoPoint(18.3930, -66.1390)), hasVerifiedOwner: true
        ),
    ]

    nonisolated static let crisisReports: [Report] = [
        crisisReport(100, .hasGas, ID.pumaLosFiltros, minutesAgo: 15, votes: .confirmed(by: 5)),
        crisisReport(101, .queue, ID.pumaLosFiltros, minutesAgo: 15, value: .queueMinutes(20)),
        crisisReport(102, .hasGas, ID.totalSanturce, minutesAgo: 25, votes: .confirmed(by: 4)),
        crisisReport(103, .hasDiesel, ID.totalSanturce, minutesAgo: 25, votes: .confirmed(by: 4)),
        crisisReport(104, .noGas, ID.shellRioPiedras, minutesAgo: 40),
        crisisReport(105, .hasIce, ID.totalSanturce, minutesAgo: 30, votes: .confirmed(by: 2)),
        // Past the 2-hour window: behind "Ver reportes anteriores".
        crisisReport(106, .hasGas, ID.losPaseos, minutesAgo: 3 * 60, votes: .confirmed(by: 2)),
        crisisReport(107, .hasDiesel, ID.losPaseos, minutesAgo: 3 * 60 + 20),
        crisisReport(108, .businessOnGenerator, CrisisID.farmaciaFrailes, minutesAgo: 60, votes: .confirmed(by: 2)),
        crisisReport(109, .businessOnGenerator, CrisisID.colmadoSantaRosa, minutesAgo: 2 * 60, source: .owner),
    ]

    /// LUMA confirms the Caguas outage; neighbours add Río Cañas to the south.
    nonisolated static let crisisCaguas = OutageArea(
        id: "outage.power.caguas-bairoa", layer: .power, municipio: "Caguas", barrios: ["Bairoa", "Tomás de Castro"],
        region: .central,
        polygon: [GeoPoint(18.2650, -66.0480), GeoPoint(18.2650, -66.0200), GeoPoint(18.2480, -66.0200), GeoPoint(18.2480, -66.0480)],
        lifecycle: .confirmed, officialAgency: .luma,
        evidence: .init(distinctDevices: 19, disputeShare: 0, matchesOfficial: true),
        openedAt: ago(minutes: 152), latestEvidenceAt: ago(minutes: 4),
        estimatedRestore: DateInterval(start: now, end: now.addingTimeInterval(.hours(21.5))),
        officialSince: ago(minutes: 140),
        communityExtension: .init(
            barrios: ["Río Cañas"],
            polygon: [GeoPoint(18.2480, -66.0480), GeoPoint(18.2480, -66.0280), GeoPoint(18.2340, -66.0280), GeoPoint(18.2340, -66.0480)],
            distinctDevices: 12
        )
    )

    nonisolated static let crisisOutageAreas: [OutageArea] = outageAreas.map { $0.id == crisisCaguas.id ? crisisCaguas : $0 }

    private static func crisisReport(
        _ number: Int, _ kind: ReportKind, _ placeID: Place.ID, minutesAgo: Double,
        value: ReportValue? = nil, source: Source = .community, votes: Votes = Votes()
    ) -> Report {
        Report(id: fixtureID(number), kind: kind, value: value, placeID: placeID, capturedAt: ago(minutes: minutesAgo), source: source, votes: votes)
    }
}
