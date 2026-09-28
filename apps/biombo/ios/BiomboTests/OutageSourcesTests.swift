@testable import Biombo
import Foundation
import SwiftUI
import Testing

@MainActor
@Suite("Outage areas: source mix, timeline, edges and road wording")
struct OutageSourcesTests {
    let caguas = SampleData.crisisCaguas

    @Test("LUMA's outline and the neighbours past it stay apart, barrio by barrio")
    func sourceMix() {
        let mix = SourceMix(caguas)
        #expect(mix.agency == .luma)
        #expect(mix.agreeing == 19)
        #expect(mix.extending == 12)
        #expect(mix.neighbours == 31)
        #expect(mix.saidBack == 0)
        #expect(mix.hasExtension)
        #expect(mix.barrios.map(\.name) == ["Bairoa", "Tomás de Castro", "Río Cañas"])
        #expect(mix.barrios.map(\.voice) == [.official(.luma), .official(.luma), .neighbours])
        // The bar asks one question: still out or back, whoever's outline they are in.
        #expect(mix.parts.map(\.count) == [31, 0])
    }

    @Test("The agreement headline says the same counts as its bar", arguments: [
        "outage.power.mayaguez-miradero", "outage.power.caguas-bairoa", "outage.water.guaynabo-frailes",
    ])
    func headlineMatchesBar(id: String) throws {
        let area = try #require((SampleData.outageAreas + [caguas]).first { $0.id == id })
        let mix = SourceMix(area)
        #expect(mix.parts.map(\.count) == [mix.stillOut, mix.saidBack])
        #expect(mix.stillOut + mix.saidBack == mix.neighbours)
        let expected: LocalizedStringResource = mix.saidBack == 0
            ? "\(mix.stillOut) vecinos lo confirman; nadie ha dicho que volvió."
            : "\(mix.stillOut) vecinos lo confirman; \(mix.saidBack) dicen que volvió."
        #expect(String(localized: mix.headline) == String(localized: expected))
    }

    @Test("A community area counts who says it came back, never a restore estimate")
    func communityMix() throws {
        let miradero = try #require(SampleData.outageAreas.first { $0.id == "outage.power.mayaguez-miradero" })
        let mix = SourceMix(miradero)
        #expect(mix.agency == nil)
        #expect(mix.saidBack == 2)
        #expect(!mix.hasExtension)
        #expect(mix.parts.map(\.count) == [3, 2])
    }

    @Test("An estimate is said as a window people use, never a clock time")
    func estimateWindow() throws {
        let now = SampleData.now // Sunday 5:30 p. m.
        let lumaEnd = try #require(caguas.estimatedRestore?.end)
        let window = DayWindow(lumaEnd, now: now)
        #expect(window == DayWindow(now.addingTimeInterval(.hours(21.5)), now: now))
        #expect(window.day == .tomorrow)
        #expect(window.part == .afternoon)
        #expect(window.text(locale: Locale(identifier: "es")).key == "mañana en la tarde")
        #expect(DayWindow(now.addingTimeInterval(.hours(1)), now: now).day == .today)
        // 2 a. m. Monday is still Sunday night.
        let smallHours = DayWindow(now.addingTimeInterval(.hours(8.5)), now: now)
        #expect(smallHours.day == .today)
        #expect(smallHours.part == .night)
        let tuesday = DayWindow(now.addingTimeInterval(.hours(36)), now: now)
        #expect(tuesday.part == .morning)
        if case .later = tuesday.day {} else { Issue.record("Expected a later weekday") }
    }

    @Test("The timeline says how long after the first neighbour the agency spoke")
    func timeline() {
        let timeline = AreaTimeline(caguas)
        #expect(timeline.entries.map(\.event) == [.firstNeighbour, .official(.luma), .latestConfirmation])
        #expect(timeline.officialLag == .minutes(12))
        #expect(timeline.entries.map(\.date) == timeline.entries.map(\.date).sorted())
    }

    @Test("A planned outage starts with the plan: no first neighbour, no lag")
    func plannedTimeline() throws {
        let plan = try #require(SampleData.outageAreas.first { $0.isPlanned })
        let timeline = AreaTimeline(plan)
        #expect(timeline.entries.first?.event == .official(.aaa))
        #expect(timeline.officialLag == nil)
    }

    @Test("The neighbours-only part is drawn with its own confidence; a watch in Río Cañas is covered")
    func extensionPart() throws {
        let status = try #require(AnswerResolver().areaStatuses([caguas], isCrisis: true, now: SampleData.now).first)
        #expect(status.label == .official(.luma))
        #expect(status.confidence == .high)
        #expect(status.extensionConfidence == .high)
        #expect(status.drawnExtension != nil)
        #expect(caguas.allBarrios.contains("Río Cañas"))
    }

    @Test("Edges carry confidence as shape: solid, dashed, dotted")
    func edges() {
        let high: AreaConfidence? = .high
        let medium: AreaConfidence? = .medium
        let low: AreaConfidence? = .low
        let unknown: AreaConfidence? = nil
        #expect(high.edge.dash.isEmpty)
        #expect(medium.edge.dash == [7, 4])
        #expect(low.edge.lineCap == .round)
        #expect(unknown.edge.dash.isEmpty)
    }

    @Test("The crisis outage detail carries the mix and timeline; its full tier drops the generic neighbours section")
    func crisisDetail() throws {
        let snapshot = SampleData.snapshot(crisis: true)
        let areas = AnswerResolver().areaStatuses(snapshot.outageAreas, isCrisis: true, now: snapshot.generatedAt)
        let detail = try #require(PlaceDetailBuilder().detail(for: .area(caguas.id, .power), snapshot: snapshot, areas: areas))
        #expect(detail.sourceMix?.extending == 12)
        #expect(detail.timeline?.officialLag == .minutes(12))
        #expect(detail.watchTarget(in: snapshot.places)?.id == SampleData.ID.bairoa)
        #expect(detail.watchDraft(in: snapshot.places)?.barrio == "Bairoa")
    }

    @Test("Roads with nothing reported say only that; no string ever says a road is safe")
    func roadWording() throws {
        let far = HomeDigest(snapshot: SampleData.snapshot(), vantage: GeoPoint(17.9, -65.3), visibleLayers: Set(Layer.allCases))
        #expect(far.layers.first { $0.layer == .roads }?.live == .noRoadProblems)
        #expect(far.layers.first { $0.layer == .roads }?.hasNews == false)

        let forbidden = ["pasable", "segura", "se puede pasar", "despejada", "passable", "is safe", "you can get through", "all clear"]
        // Spanish is the source language, so the English table's keys are the Spanish strings.
        let path = try #require(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en"))
        let table = try #require(NSDictionary(contentsOfFile: path) as? [String: String])
        #expect(table.count > 100)
        for (spanish, english) in table {
            for text in [spanish, english] {
                #expect(!forbidden.contains { text.lowercased().contains($0) }, "\(text)")
            }
        }
    }

    @Test("A road with no official notice says so; a DTOP closure in its municipio counts")
    func roadNotice() throws {
        let snapshot = SampleData.snapshot()
        let builder = PlaceDetailBuilder()
        let comerio = try #require(builder.detail(for: .place(SampleData.ID.pr156Comerio, .roads), snapshot: snapshot, areas: []))
        #expect(comerio.hasRoadNotice)
        let caguas = try #require(builder.detail(for: .place(SampleData.ID.pr52Caguas, .roads), snapshot: snapshot, areas: []))
        #expect(!caguas.hasRoadNotice)
    }
}
