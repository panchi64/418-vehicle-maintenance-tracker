@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("Gasolina y planta: availability, bad news and generators")
struct AvailabilityTests {
    let crisis = SampleData.snapshot(crisis: true)

    private func digest(_ snapshot: PlacesSnapshot) -> AvailabilityDigest {
        AvailabilityBuilder().make(snapshot: snapshot, vantage: snapshot.vantage)
    }

    @Test("Gasoline: the nearest station with fuel answers, with its line; stations without it are apart")
    func gasoline() throws {
        let gasoline = digest(crisis).gasoline
        let lead = try #require(gasoline.lead)
        #expect(lead.place.id == SampleData.ID.pumaLosFiltros)
        #expect(lead.queueMinutes == 20)
        #expect(gasoline.stops.map(\.distance) == gasoline.stops.map(\.distance).sorted())
        #expect(gasoline.stops.contains { $0.place.id == SampleData.ID.totalSanturce })
        #expect(gasoline.without.map(\.place.id) == [SampleData.ID.shellRioPiedras])
        #expect(!gasoline.stops.contains { $0.place.id == SampleData.ID.shellRioPiedras })
    }

    @Test("Diesel is its own answer; a diesel price counts as having it")
    func diesel() throws {
        let diesel = digest(crisis).diesel
        #expect(try #require(diesel.lead).place.id == SampleData.ID.totalSanturce)
        #expect(diesel.stops.contains { $0.place.id == SampleData.ID.gulfBairoa })
        #expect(diesel.without.isEmpty)
        // A line is reported at the gas pumps; the diesel answer never repeats it.
        #expect(digest(crisis).gasoline.stops.contains { $0.queueMinutes != nil })
        #expect(diesel.stops.allSatisfy { $0.queueMinutes == nil })
    }

    @Test("Reports past the 2-hour window wait behind older reports, per fuel")
    func older() {
        let availability = digest(crisis)
        #expect(availability.gasoline.older.count == 1)
        #expect(availability.diesel.older.count == 1)
        #expect(availability.gasoline.window == .hours(2))
        #expect(availability.gasoline.others(cap: 3).count <= 3)
        #expect(availability.gasoline.others(cap: 3).first?.id != availability.gasoline.lead?.id)
    }

    @Test("Generators: open on a planta or with ice, nearest first")
    func generators() {
        let generators = digest(crisis).generators
        let ids = generators.map(\.item.id)
        #expect(ids.contains(PlaceAnswer.currentID(place: SampleData.CrisisID.farmaciaFrailes, layer: .businesses)))
        #expect(ids.contains(PlaceAnswer.currentID(place: SampleData.CrisisID.colmadoSantaRosa, layer: .businesses)))
        #expect(ids.contains(PlaceAnswer.currentID(place: SampleData.ID.totalSanturce, layer: .gas)))
        #expect(generators.map(\.distance) == generators.map(\.distance).sorted())
    }

    @Test("The crisis answer names the same station as Gasolina y planta")
    func answerAgrees() throws {
        let home = HomeDigest(snapshot: crisis, vantage: crisis.vantage, visibleLayers: Layer.defaultVisible(inCrisis: true))
        guard case .nearestFuel(let answer, _) = home.nearby.facts.last else {
            Issue.record("Expected the nearest fuel")
            return
        }
        #expect(answer.place.id == home.availability.gasoline.lead?.place.id)
        #expect(home.nearby.section(.cheapestGas) == nil)
        #expect(home.nearby.section(.openNow) == nil)
    }

    @Test("An owner's hay stays the answer, but 3 neighbours saying no hay make it disputed news")
    func ownerDispute() throws {
        var snapshot = SampleData.snapshot()
        let station = try #require(snapshot.places.firstIndex { $0.id == SampleData.ID.pumaLosFiltros })
        snapshot.places[station].hasVerifiedOwner = true
        let place = snapshot.places[station].id
        snapshot.reports = [
            Report(kind: .hasGas, placeID: place, capturedAt: SampleData.ago(minutes: 30), source: .owner),
            Report(kind: .noGas, placeID: place, capturedAt: SampleData.ago(minutes: 10)),
            Report(kind: .noGas, placeID: place, capturedAt: SampleData.ago(minutes: 5), votes: Votes(confirmWeight: 1, confirmCount: 1)),
        ]
        let lead = try #require(digest(snapshot).gasoline.lead)
        #expect(lead.answer.kind == .hasGas)
        #expect(lead.isDisputed)
        #expect(lead.trust(now: SampleData.now).phrase == .disputed(.minutes(30)))

        snapshot.reports.removeLast()
        #expect(digest(snapshot).gasoline.lead?.isDisputed == false)
    }

    @Test("With nobody reporting fuel, the answer is empty, not old")
    func empty() {
        let far = AvailabilityBuilder().make(snapshot: crisis, vantage: GeoPoint(17.9, -65.3))
        #expect(far.gasoline.lead == nil)
        #expect(far.generators.isEmpty)
    }
}
