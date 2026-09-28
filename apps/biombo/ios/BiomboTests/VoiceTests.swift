@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("Siri: voice reports, ¿Hay luz?, watching and checking by voice")
struct VoiceTests {
    private let spanish = Locale(identifier: "es_PR")

    private func context(crisis: Bool = false, watches: [WatchedPlace] = SampleData.watchedPlaces) -> IntentContext {
        IntentContext(
            snapshots: SnapshotStore(),
            device: DeviceStore(),
            watches: WatchStore(places: watches),
            contributions: ContributionStore(),
            provider: { SamplePlacesProvider(crisis: crisis) }
        )
    }

    private func areas(crisis: Bool = false) -> [AreaStatus] {
        let snapshot = SampleData.snapshot(crisis: crisis)
        return HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: Set(Layer.allCases)).areas
    }

    @Test("¿Hay luz? names who says so and since when, or that nothing recent is known")
    func conditionAnswers() {
        let caguas = ConditionAnswer.make(service: .power, municipio: "caguas", areas: areas())
        guard case .out(let status) = caguas else {
            Issue.record("Expected Caguas out")
            return
        }
        #expect(status.id == "outage.power.caguas-bairoa")
        let sentence = caguas.sentence(service: .power, municipio: "Caguas", now: SampleData.now, locale: spanish).string(in: spanish)
        #expect(sentence.hasPrefix("Vecinos confirman que partes de Caguas están sin luz desde las 3:10"))

        guard case .restoring = ConditionAnswer.make(service: .power, municipio: "Mayagüez", areas: areas()) else {
            Issue.record("Expected Mayagüez restoring")
            return
        }
        let ponce = ConditionAnswer.make(service: .power, municipio: "Ponce", areas: areas())
        #expect(ponce == .noRecent)
        #expect(ponce.sentence(service: .power, municipio: "Ponce", now: SampleData.now, locale: spanish).string(in: spanish) == "No hay reportes recientes de luz en Ponce.")
        #expect(ConditionAnswer.make(service: .water, municipio: "Caguas", areas: areas()) == .noRecent, "Each service answers for itself")
    }

    @Test("An official outage is said with its agency, and after a voice report too")
    func officialAnswer() throws {
        let answer = ConditionAnswer.make(service: .power, municipio: "Caguas", areas: areas(crisis: true))
        let sentence = answer.sentence(service: .power, municipio: "Caguas", now: SampleData.now, locale: spanish).string(in: spanish)
        #expect(sentence.hasPrefix("LUMA dice que partes de Caguas están sin luz"))
        let line = try #require(answer.officialLine(service: .power, municipio: "Caguas", locale: spanish))
        #expect(line.string(in: spanish).hasPrefix("LUMA ya reporta sin luz en partes de Caguas"))
        #expect(ConditionAnswer.make(service: .power, municipio: "Caguas", areas: areas()).officialLine(service: .power, municipio: "Caguas", locale: spanish) == nil)
    }

    @Test("A voice report lands where you stand, is said to Siri, and joins the outbox and Tu aporte")
    func voiceReport() async throws {
        let context = context()
        let voice = try #require(await ReportConditionIntent.draft(.noPower, from: nil, in: context))
        #expect(voice.target.place.id == SampleData.ID.puebloViejo)
        #expect(voice.report.channel == .siri)
        #expect(voice.question(locale: spanish).string(in: spanish).hasPrefix("¿Envío “Sin luz” en "))
        #expect(context.device.outbox.isEmpty, "Nothing is queued before the yes")

        context.queue(voice)
        #expect(context.device.outbox.contains(voice.id))
        #expect(context.contributions.history.contains { $0.id == voice.id })
    }

    @Test("From a watched place, the report lands there; with nothing of that kind in reach there is none")
    func voiceReportPlaces() async throws {
        let context = context()
        let mama = try #require(SampleData.watchedPlaces.first { $0.name == "Casa de Mamá" })
        let there = try #require(await ReportConditionIntent.draft(.noPower, from: mama.id, in: context))
        #expect(there.target.place.municipio == mama.municipio)
        let snapshot = SampleData.snapshot()
        #expect(VoiceReport.make(.noGas, at: GeoPoint(18.20, -67.14), snapshot: snapshot, areas: []) == nil)
    }

    @Test("Voice conditions are distinct report kinds")
    func conditions() {
        let kinds = ReportCondition.allCases.map(\.kind)
        #expect(Set(kinds).count == kinds.count)
        #expect(ReportCondition.roadClosed.kind == .closed)
        #expect(CheckedService.allCases.map(\.layer) == [.power, .water, .signal])
    }

    @Test("Watching by voice: named as said, never twice, never past the limit")
    func watchByVoice() throws {
        let store = WatchStore()
        let snapshot = SampleData.snapshot()
        let place = try #require(snapshot.places.first { $0.kind == .area })
        let first = WatchPlaceIntent.watch(.draft(for: place), named: "  Casa de Mamá ", in: store)
        guard case .started(let watch) = first else {
            Issue.record("Expected a new watch")
            return
        }
        #expect(watch.name == "Casa de Mamá")
        #expect(watch.layers == WatchedPlace.defaultLayers)
        #expect(WatchPlaceIntent.watch(.draft(for: place), named: nil, in: store) == .alreadyWatched(watch))

        let full = WatchStore(places: (0..<WatchedPlace.limit).map { index in
            WatchedPlace(name: "\(index)", location: GeoPoint(18, -66), municipio: "M\(index)")
        })
        #expect(WatchPlaceIntent.watch(.draft(municipio: "Ponce", at: GeoPoint(18, -66.6)), named: nil, in: full) == .full)
        #expect(WatchOutcome.full.sentence(notificationsAllowed: true, locale: spanish).string(in: spanish).contains("\(WatchedPlace.limit)"))
    }

    @Test("¿Cómo está Casa de Mamá? says the confirmed changes, or Todo normal")
    func checkWatched() async throws {
        let context = context()
        let mama = try #require(SampleData.watchedPlaces.first { $0.name == "Casa de Mamá" })
        let said = await CheckWatchedPlaceIntent.answer(for: mama.id, context: context, locale: spanish)
        #expect(said.hasPrefix("En Casa de Mamá: "))
        let abuela = try #require(SampleData.watchedPlaces.first { $0.name == "Casa de Abuela" })
        #expect(await CheckWatchedPlaceIntent.answer(for: abuela.id, context: context, locale: spanish) == "Todo normal en Casa de Abuela.")
    }

    @Test("Gas by voice uses the widget's pick, in the user's unit")
    func fuelByVoice() async {
        let said = await CheckFuelIntent.answer(context: context(), unit: .litre, locale: spanish)
        #expect(said.hasPrefix("La gasolina más barata cerca está en "))
        #expect(said.contains("el litro"))
        #expect(CheckFuelIntent.sentence(nil, unit: .litre, locale: spanish).string(in: spanish) == "No hay reportes recientes de gasolina cerca.")
        let crisis = await CheckFuelIntent.answer(context: context(crisis: true), unit: .litre, locale: spanish)
        #expect(crisis.hasPrefix("Hay gasolina en "))
    }

    @Test("Siri knows all 78 municipios, accents or not")
    func municipios() {
        #expect(PuertoRico.municipios.count == 78)
        #expect(Set(PuertoRico.municipios).count == 78)
        #expect(PuertoRico.municipio(named: "mayaguez") == "Mayagüez")
        #expect(PuertoRico.municipio(named: "Narnia") == nil)
        #expect(SampleData.snapshot().places.allSatisfy { PuertoRico.municipios.contains($0.municipio) })
    }
}
