@testable import Biombo
import Foundation
import Testing

@Suite("Place detail: areas, reports behind the answer, notices and ports")
struct PlaceDetailAreaTests {
    let snapshot = SampleData.snapshot()
    let builder = PlaceDetailBuilder()

    private var digest: HomeDigest {
        HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: Set(Layer.allCases))
    }

    private func detail(_ selection: Selection, in snapshot: PlacesSnapshot? = nil) throws -> PlaceDetail {
        let snapshot = snapshot ?? self.snapshot
        let areas = AnswerResolver().areaStatuses(snapshot.outageAreas, isCrisis: false, now: snapshot.generatedAt)
        return try #require(builder.detail(for: selection, snapshot: snapshot, areas: areas))
    }

    @Test("An area carries the reports filed on its barrio, newest first; the 911 line stays with the downed line, not the area")
    func areaEvidence() throws {
        let bairoa = try detail(.area("outage.power.caguas-bairoa", .power))
        #expect(Set(bairoa.evidence.map(\.kind)) == [.noPower, .lineDown])
        #expect(bairoa.evidence.map(\.asOf) == bairoa.evidence.map(\.asOf).sorted(by: >))
        #expect(!bairoa.isLineDown)
        #expect(bairoa.listsNeighbourReports)
        #expect(bairoa.hasFullSections)
        // Depth holds only what the full tier didn't list.
        #expect(Set(bairoa.depthCommunityReports).isDisjoint(with: bairoa.fullNeighbourReports))
    }

    @Test("Searching a barrio with an open outage opens the outage, not its point reports")
    func searchOpensArea() throws {
        let bairoa = try #require(snapshot.places.first { $0.id == SampleData.ID.bairoa })
        #expect(digest.selection(forSearched: bairoa) == .area("outage.power.caguas-bairoa", .power))
        let comerio = try #require(snapshot.places.first { $0.id == SampleData.ID.comerioPueblo })
        #expect(digest.selection(forSearched: comerio) == .place(SampleData.ID.comerioPueblo, .water))
    }

    @Test("Water lists distribution points apart from neighbours' reports")
    func waterPoints() throws {
        let bairoa = try detail(.place(SampleData.ID.bairoa, .water))
        #expect(bairoa.waterPoints.map(\.kind) == [.waterPoint])
        #expect(!bairoa.neighbourReports.contains { $0.kind == .waterPoint })
    }

    @Test("An owner's post is kept apart from what neighbours say")
    func ownerApart() throws {
        let carmen = try detail(.place(SampleData.ID.colmadoDonaCarmen, .businesses))
        #expect(carmen.ownerReports.map(\.kind) == [.businessOpen])
        #expect(carmen.communityReports.map(\.kind) == [.businessClosed])
    }

    @Test("An empty station still says DACO's reference for its brand")
    func emptyStationReference() throws {
        let cidra = try detail(.place(SampleData.ID.shellCidra, .gas))
        guard case .brand(let daco) = cidra.reference else {
            Issue.record("Expected Shell's DACO reference")
            return
        }
        #expect(daco.brand == "Shell")
        #expect(try detail(.place(SampleData.ID.pumaLosFiltros, .gas)).reference == nil)
    }

    @Test("A place with nothing past the summary has no full sections")
    func noFullSections() throws {
        let farmacia = try detail(.place(SampleData.ID.farmaciaDelPueblo, .businesses))
        #expect(!farmacia.hasFullSections)
    }

    @Test("Ports read the same current reports as the answer")
    func ports() throws {
        let place = try #require(snapshot.places.first { $0.id == SampleData.ID.chargerPlazaAmericas })
        let works = AnswerResolver().currentReports(for: place, layer: .chargers, reports: snapshot.reports, now: snapshot.generatedAt)
        #expect(PortStatus.statuses(for: place, evidence: works).map(\.status) == [.chargerWorks, nil])
        #expect(PortStatus.statuses(for: place, evidence: []).map(\.status) == [nil, nil])
    }

    @Test("Official cards: one per agency, actionable first, then newest")
    func noticeOrdering() throws {
        var snapshot = self.snapshot
        let now = snapshot.generatedAt
        snapshot.notices += [
            OfficialNotice(id: "old", agency: .dtop, kind: .roadClosure, layer: .roads, headline: "Vieja.",
                           municipios: ["Comerío"], issuedAt: now.addingTimeInterval(-.hours(9)), updatedAt: now.addingTimeInterval(-.hours(9)),
                           isFeed: false),
            OfficialNotice(id: "act", agency: .nmead, kind: .roadClosure, layer: .roads, headline: "Desvío.", guidance: "Usa la PR-172.",
                           municipios: ["Comerío"], issuedAt: now.addingTimeInterval(-.hours(10)), updatedAt: now.addingTimeInterval(-.hours(10)),
                           isFeed: false),
            OfficialNotice(id: "shelter", agency: .nmead, kind: .shelter, layer: .roads, headline: "Refugio.", guidance: "Ve al refugio.",
                           municipios: ["Comerío"], issuedAt: now.addingTimeInterval(-.hours(1)), updatedAt: now.addingTimeInterval(-.hours(1)),
                           isFeed: false),
            OfficialNotice(id: "other-stretch", agency: .dtop, kind: .roadClosure, layer: .roads, headline: "Cerrada la PR-173.",
                           municipios: ["Comerío"], issuedAt: now.addingTimeInterval(-.hours(1)), updatedAt: now.addingTimeInterval(-.hours(1)),
                           isFeed: false, placeIDs: ["road.pr-173"]),
        ]
        let road = try detail(.place(SampleData.ID.pr156Comerio, .roads), in: snapshot)
        #expect(road.otherNotices.map(\.agency) == [.nmead, .dtop])
        #expect(road.otherNotices.last?.notices.map(\.id) == ["notice.dtop.pr156", "old"])
        // A segment hears only closures for its stretch: no shelters, no other roads.
        #expect(road.otherNotices.first?.notices.map(\.id) == ["act"])
        #expect(road.hasRoadNotice)
    }

    @Test("A flooded stretch lists no warning, shelter or repeated flood guidance, and says no closure covers it")
    func floodedStretch() throws {
        let road = try detail(.place(SampleData.ID.pr52Caguas, .roads), in: SampleData.snapshot(crisis: true))
        #expect(road.otherNotices.isEmpty)
        #expect(road.lacksRoadNotice)
        #expect(road.isFlood)
        // The answer's own report isn't repeated as a neighbour row.
        #expect(!road.neighbourReports.contains { $0.lead.id == road.answer?.lead.id })
    }

    @MainActor
    @Test("Diesel follow-ups and hazards ask about what was reported")
    func questions() {
        let locale = Locale(identifier: "es")
        #expect(ConfirmQuestion.price(FuelPrice(grade: .diesel, centsPerLitre: 108)).noLongerReply.key == ReportKind.noDiesel.word.key)
        #expect(ConfirmQuestion.status(.cloudyWater).text(unit: .litre, locale: locale).key == "¿Sigue turbia?")
        #expect(ConfirmQuestion.status(.businessOnGenerator).text(unit: .litre, locale: locale).key == "¿Sigue con planta?")
    }

    @Test("The painting's anchor stays inside the visible region wherever the camera is")
    func paintedAnchor() {
        for (latitude, longitude, span) in [(18.2, -67.14, 0.15), (18.45, -65.3, 0.35), (18.2, -66.4, 1.0)] {
            let anchor = PaintedGround.anchor(centerLatitude: latitude, centerLongitude: longitude, latitudeDelta: span * 2, longitudeDelta: span)
            #expect(abs(anchor.longitude - longitude) < span / 2)
            #expect(anchor.latitude < latitude + span && anchor.latitude > latitude + span * 0.8)
        }
    }
}
