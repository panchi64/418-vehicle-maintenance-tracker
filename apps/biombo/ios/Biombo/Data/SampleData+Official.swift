import Foundation

/// SAMPLE DATA — invented outage areas, official notices and DACO references.
/// No agency issued these; they exist to exercise the UI's official treatment.
nonisolated extension SampleData {
    nonisolated static let outageAreas: [OutageArea] = [
        // Community-confirmed power outage: "Caguas sigue sin luz desde las 3:10 p. m."
        OutageArea(
            id: "outage.power.caguas-bairoa", layer: .power, municipio: "Caguas", barrios: ["Bairoa"],
            region: .central, polygon: bairoaRing, lifecycle: .confirmed,
            evidence: .init(distinctDevices: 7, disputeShare: 0.1),
            openedAt: ago(minutes: 140), latestEvidenceAt: ago(minutes: 35)
        ),
        // Restoring: neighbours report the power back in part.
        OutageArea(
            id: "outage.power.mayaguez-miradero", layer: .power, municipio: "Mayagüez", barrios: ["Miradero"],
            region: .west, polygon: miraderoRing, lifecycle: .restoring,
            evidence: .init(distinctDevices: 5, disputeShare: 0.4),
            openedAt: ago(minutes: 9 * 60), latestEvidenceAt: ago(minutes: 20)
        ),
        // Official AAA plan: "Guaynabo está en el plan de interrupciones".
        OutageArea(
            id: "outage.water.guaynabo-frailes", layer: .water, municipio: "Guaynabo", barrios: ["Frailes", "Santa Rosa"],
            region: .metro,
            polygon: [GeoPoint(18.3850, -66.1300), GeoPoint(18.3850, -66.1100), GeoPoint(18.3650, -66.1100), GeoPoint(18.3650, -66.1300)],
            lifecycle: .confirmed, officialAgency: .aaa,
            evidence: .init(distinctDevices: 4, disputeShare: 0, matchesOfficial: true),
            openedAt: ago(minutes: 20 * 60), latestEvidenceAt: ago(minutes: 3 * 60),
            estimatedRestore: DateInterval(start: now, end: now.addingTimeInterval(.hours(36))),
            isPlanned: true
        ),
        // Low confidence, per carrier: drawn dotted with "Pocos reportes".
        OutageArea(
            id: "outage.signal.claro.barranquitas", layer: .signal, carrier: .claro, municipio: "Barranquitas",
            barrios: ["Quebrada Grande"], region: .central,
            polygon: [GeoPoint(18.1950, -66.3150), GeoPoint(18.1950, -66.2980), GeoPoint(18.1800, -66.2980), GeoPoint(18.1800, -66.3150)],
            lifecycle: .open, evidence: .init(distinctDevices: 3, disputeShare: 0),
            openedAt: ago(minutes: 120), latestEvidenceAt: ago(minutes: 50)
        ),
    ]

    nonisolated static let notices: [OfficialNotice] = [
        OfficialNotice(
            id: "notice.aaa.boil.comerio", agency: .aaa, kind: .boilWater, layer: .water,
            headline: "Aviso de hervir el agua en Comerío.", guidance: "Hierve el agua 3 minutos antes de tomarla.",
            municipios: ["Comerío"], issuedAt: ago(minutes: 26 * 60), updatedAt: ago(minutes: 26 * 60),
            isFeed: false, isStaffTranscription: true
        ),
        OfficialNotice(
            id: "notice.aaa.plan.guaynabo", agency: .aaa, kind: .waterInterruptionPlan, layer: .water,
            headline: "Guaynabo está en el plan de interrupciones hasta el martes a las 6 a. m.",
            municipios: ["Guaynabo"], issuedAt: ago(minutes: 20 * 60), updatedAt: ago(minutes: 20 * 60),
            expiresAt: now.addingTimeInterval(.hours(36)), isFeed: false, isStaffTranscription: true
        ),
        OfficialNotice(
            id: "notice.dtop.pr156", agency: .dtop, kind: .roadClosure, layer: .roads,
            headline: "Cerrada la PR-156, km 31, en Comerío por un derrumbe.",
            municipios: ["Comerío"], issuedAt: ago(minutes: 4 * 60), updatedAt: ago(minutes: 4 * 60),
            expiresAt: now.addingTimeInterval(.hours(48)), isFeed: false, isStaffTranscription: true,
            placeIDs: [ID.pr156Comerio]
        ),
    ]

    /// Added on top of `notices` when the sample runs in crisis mode.
    nonisolated static let crisisNotices: [OfficialNotice] = [
        OfficialNotice(
            id: "notice.nws.tropical-storm", agency: .nws, kind: .weatherWarning, layer: .roads,
            headline: "Puerto Rico está en aviso de tormenta tropical.",
            guidance: "No cruces carreteras inundadas.",
            municipios: [], issuedAt: ago(minutes: 6 * 60), updatedAt: ago(minutes: 25), isFeed: true
        ),
        OfficialNotice(
            id: "notice.nmead.shelter.caguas", agency: .nmead, kind: .shelter, layer: .roads,
            headline: "Refugio abierto en el Centro Comunal de Bairoa, Caguas.",
            municipios: ["Caguas"], issuedAt: ago(minutes: 3 * 60), updatedAt: ago(minutes: 3 * 60),
            expiresAt: now.addingTimeInterval(.hours(48)), isFeed: false
        ),
    ]

    /// One reference per brand and grade, published today.
    nonisolated static let dacoReferences: [DacoReference] = [
        ("Puma", 102.0), ("Total", 101), ("Shell", 102), ("Gulf", 99), ("Texaco", 100),
    ].map { brand, cents in
        DacoReference(brand: brand, price: FuelPrice(grade: .regular, centsPerLitre: cents), publishedOn: ago(minutes: 11 * 60))
    }
}
