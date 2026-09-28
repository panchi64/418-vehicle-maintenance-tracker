@testable import Biombo
import Foundation
import Testing

@Suite("Crisis mode: triggers, hold and all-clear")
struct CrisisRulesTests {
    let rules = CrisisRules()
    let start = SampleData.now

    private func at(minutes: Double) -> Date { start.addingTimeInterval(.minutes(minutes)) }

    @Test("An NWS warning turns it on at once, with its start time")
    func nwsOn() {
        let state = rules.step(.ordinary, readings: CrisisReadings(nwsWarning: .live(true)), now: start)
        #expect(state.isActive)
        #expect(state.triggers == [.nwsWarning])
        #expect(state.since == start)
    }

    @Test("LUMA over 10% counts only once it has held 30 minutes")
    func lumaHold() {
        let readings = CrisisReadings(lumaOutShare: .live(0.12))
        var state = rules.step(.ordinary, readings: readings, now: start)
        #expect(!state.isActive)
        #expect(state.lumaAboveSince == start)
        state = rules.step(state, readings: readings, now: at(minutes: 29))
        #expect(!state.isActive)
        state = rules.step(state, readings: readings, now: at(minutes: 30))
        #expect(state.triggers == [.lumaCustomersOut])
    }

    @Test("A dip below the threshold restarts LUMA's hold")
    func lumaDip() {
        var state = rules.step(.ordinary, readings: CrisisReadings(lumaOutShare: .live(0.12)), now: start)
        state = rules.step(state, readings: CrisisReadings(lumaOutShare: .live(0.08)), now: at(minutes: 20))
        #expect(state.lumaAboveSince == nil)
        state = rules.step(state, readings: CrisisReadings(lumaOutShare: .live(0.12)), now: at(minutes: 40))
        #expect(!state.isActive)
    }

    @Test("Community areas across 15% of municipios work without LUMA")
    func community() {
        let off = rules.step(.ordinary, readings: CrisisReadings(communityPowerShare: .live(0.14)), now: start)
        #expect(!off.isActive)
        let on = rules.step(.ordinary, readings: CrisisReadings(communityPowerShare: .live(0.15)), now: start)
        #expect(on.triggers == [.communityPowerAreas])
    }

    @Test("It ends only after 6 hours of all-clear, and calm interrupted starts over")
    func clearHold() {
        let on = rules.step(.ordinary, readings: CrisisReadings(nwsWarning: .live(true), communityPowerShare: .live(0.2)), now: start)
        let calm = CrisisReadings(nwsWarning: .live(false), communityPowerShare: .live(0.02))
        var state = rules.step(on, readings: calm, now: at(minutes: 60))
        #expect(state.isActive)
        #expect(state.clearSince == at(minutes: 60))
        #expect(state.triggers == on.triggers)
        state = rules.step(state, readings: CrisisReadings(nwsWarning: .live(false), communityPowerShare: .live(0.07)), now: at(minutes: 120))
        #expect(state.isActive)
        #expect(state.clearSince == nil)
        state = rules.step(state, readings: calm, now: at(minutes: 180))
        let before = rules.step(state, readings: calm, now: at(minutes: 180 + 359))
        #expect(before.isActive)
        let after = rules.step(before, readings: calm, now: at(minutes: 180 + 360))
        #expect(!after.isActive)
        #expect(CrisisRules.didEnd(from: before, to: after))
        #expect(!CrisisRules.didEnd(from: after, to: after))
    }

    @Test("A source that was live and went quiet never counts as clear; one never had is left out")
    func lostSource() {
        let on = rules.step(.ordinary, readings: CrisisReadings(nwsWarning: .live(true)), now: start)
        let lost = CrisisReadings(nwsWarning: .live(false), lumaOutShare: .lost)
        var state = rules.step(on, readings: lost, now: at(minutes: 10))
        state = rules.step(state, readings: lost, now: at(minutes: 10 + 7 * 60))
        #expect(state.isActive)
        #expect(state.clearSince == nil)

        let unavailable = CrisisReadings(nwsWarning: .live(false), lumaOutShare: .unavailable)
        state = rules.step(on, readings: unavailable, now: at(minutes: 10))
        state = rules.step(state, readings: unavailable, now: at(minutes: 10 + 6 * 60))
        #expect(!state.isActive)
    }

    @Test("A declared crisis ends only by declaration; a withdrawn one leaves automatic triggers to their hold")
    func declaration() {
        let declared = CrisisReadings(declaration: ["Caguas"])
        var state = rules.step(.ordinary, readings: declared, now: start)
        #expect(state.triggers == [.declaration])
        #expect(state.municipios == ["Caguas"])
        state = rules.step(state, readings: declared, now: at(minutes: 24 * 60))
        #expect(state.isActive)
        state = rules.step(state, readings: CrisisReadings(), now: at(minutes: 24 * 60 + 1))
        #expect(!state.isActive)

        let both = rules.step(.ordinary, readings: CrisisReadings(nwsWarning: .live(true), declaration: []), now: start)
        let withdrawn = rules.step(both, readings: CrisisReadings(nwsWarning: .live(false)), now: at(minutes: 30))
        #expect(withdrawn.triggers == [.nwsWarning])
        #expect(withdrawn.clearSince == at(minutes: 30))
    }
}
