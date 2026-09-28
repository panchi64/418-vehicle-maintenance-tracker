@testable import Biombo
import Testing

@MainActor
@Suite("Home state transitions")
struct HomeStoreTests {
    @Test("Starts at peek with the default layers")
    func initialState() {
        let store = HomeStore()
        #expect(store.tier == .peek)
        #expect(store.mode == .nearby)
        #expect(store.visibleLayers == [.power, .water, .roads, .gas])
    }

    @Test("Capas drops the sheet to peek and ends search")
    func capas() {
        let store = HomeStore()
        store.beginSearch()
        store.query = "caguas"
        store.openCapas()
        #expect(store.isCapasOpen)
        #expect(store.tier == .peek)
        #expect(store.mode == .nearby)
        #expect(store.query.isEmpty)
        store.closeCapas()
        #expect(!store.isCapasOpen)
    }

    @Test("Toggling a layer hides and shows it")
    func toggle() {
        let store = HomeStore()
        store.toggle(.gas)
        #expect(!store.visibleLayers.contains(.gas))
        store.toggle(.signal)
        #expect(store.visibleLayers.contains(.signal))
    }

    @Test("Search opens full; leaving it returns to summary and clears the query")
    func search() {
        let store = HomeStore()
        store.beginSearch()
        #expect(store.tier == .full)
        #expect(store.mode == .searching)
        store.query = "puma"
        store.endSearch()
        #expect(store.tier == .summary)
        #expect(store.query.isEmpty)
    }

    @Test("Selecting opens the detail at summary, with the pin's id")
    func selection() {
        let store = HomeStore()
        store.tier = .full
        store.select(.place("station.puma-los-filtros", .gas))
        #expect(store.selectedID == "station.puma-los-filtros#gas")
        #expect(store.tier == .summary)
        store.tier = .peek
        store.select(.area("outage.power.caguas-bairoa", .power))
        #expect(store.selectedID == "outage.power.caguas-bairoa")
        #expect(store.tier == .summary)
        store.clearSelection()
        #expect(store.selectedID == nil)
    }

    @Test("Hiding the selection's layer ends it, so showing the layer again brings nothing back")
    func hiddenSelectionEnds() {
        let store = HomeStore()
        store.select(.area("outage.power.caguas-bairoa", .power))
        store.toggle(.water)
        #expect(store.selectedID != nil)
        store.toggle(.power)
        #expect(store.selectedID == nil)
        store.toggle(.power)
        #expect(store.selectedID == nil)
    }

    @Test("Picking a searched place on a hidden layer draws that layer")
    func searchPickShowsLayer() {
        let store = HomeStore()
        store.beginSearch()
        store.select(.place("charger.plaza-las-americas", .chargers))
        #expect(store.visibleLayers.contains(.chargers))
        #expect(store.selectedID == "charger.plaza-las-americas#chargers")
        #expect(store.mode == .nearby)
    }

    @Test("Tapping the same pin again keeps the reply; a new selection or closing drops pushed depth")
    func reselectAndDepthPath() {
        let store = HomeStore()
        let puma = Selection.place("station.puma-los-filtros", .gas)
        store.select(puma)
        store.reply(.same, to: .price(FuelPrice(grade: .regular, centsPerLitre: 99)))
        store.path = [.depth]
        store.select(puma)
        #expect(store.confirmStep == .answered(.same))
        #expect(store.path == [.depth])
        store.select(.place("station.gulf-bairoa", .gas))
        #expect(store.path.isEmpty)
        store.path = [.depth]
        store.clearSelection()
        #expect(store.path.isEmpty)
    }

    @Test("The confirm question starts afresh on every visit; Deshacer returns to asking")
    func confirmFlow() {
        let store = HomeStore()
        let price = ConfirmQuestion.price(FuelPrice(grade: .regular, centsPerLitre: 99))
        store.select(.place("station.puma-los-filtros", .gas))
        store.reply(.changed, to: price)
        #expect(store.confirmStep == .askingWhatChanged)
        store.reply(.otherPrice, to: price)
        #expect(store.confirmStep == .answered(.otherPrice))
        store.undoReply()
        #expect(store.confirmStep == .asking)
        store.reply(.same, to: price)
        store.select(.place("station.gulf-bairoa", .gas))
        #expect(store.confirmStep == .asking)
    }

    @Test("Vigilar opens setup; the list closes Capas; Vigilar otro lugar starts a search; Ajustes closes Capas")
    func watchAndSettings() {
        let store = HomeStore()
        let draft = SampleData.watchedPlaces[0]
        store.openCapas()
        store.openWatchList()
        #expect(store.isWatchListOpen)
        #expect(!store.isCapasOpen)
        // Setup waits for the list to finish closing: two sheets never swap in one step.
        store.beginWatch(draft)
        #expect(!store.isWatchListOpen)
        #expect(store.watchDraft == nil)
        store.watchListDidDismiss()
        #expect(store.watchDraft == draft)
        store.watchDraft = nil
        store.openWatchList()
        store.select(.place("station.puma-los-filtros", .gas))
        store.watchAnother()
        #expect(!store.isWatchListOpen)
        #expect(store.selection == nil)
        #expect(store.mode == .nearby)
        store.watchListDidDismiss()
        #expect(store.mode == .searching)
        #expect(store.searchPurpose == .watch)
        #expect(store.afterWatchList == nil)
        // A picked result opens setup and ends the search.
        store.chooseToWatch(draft)
        #expect(store.watchDraft == draft)
        #expect(store.mode == .nearby)
        #expect(store.searchPurpose == .find)
        store.openCapas()
        store.openSettings()
        #expect(store.isSettingsOpen)
        #expect(!store.isCapasOpen)
    }

    @Test("Crisis draws every service plus gas; turning it off restores the ordinary layers")
    func crisisLayers() {
        let store = HomeStore(isCrisis: true)
        #expect(store.visibleLayers == [.power, .water, .signal, .roads, .gas])
        store.expandEveryday()
        store.select(.area("outage.signal.claro.barranquitas", .signal))
        store.applyCrisis(false)
        #expect(store.visibleLayers == [.power, .water, .roads, .gas])
        #expect(!store.isEverydayExpanded)
        #expect(store.selection == nil)
    }

    @Test("Crisis turning off while its screens are open closes them")
    func crisisOffClosesItsScreens() {
        let store = HomeStore(isCrisis: true)
        store.show(.crisis)
        #expect(store.path == [.crisis])
        #expect(store.tier == .full)
        store.path.append(.availability)
        store.applyCrisis(false)
        #expect(store.path.isEmpty)
        store.path = [.outbox]
        store.applyCrisis(true)
        #expect(store.path == [.outbox])
    }

    @Test("Reportar sits at peek, sized to its content")
    func report() {
        let store = HomeStore()
        store.tier = .summary
        store.openCapas()
        store.reportHere()
        #expect(store.mode == .reporting)
        #expect(store.reportFocus == .whereYouAre)
        #expect(store.tier == .peek)
        #expect(!store.isCapasOpen)
        store.endReport()
        #expect(store.mode == .nearby)
    }

    @Test("Reportar under a detail is about the selection")
    func reportOnSelection() {
        let store = HomeStore()
        store.select(.place(SampleData.ID.pumaLosFiltros, .gas))
        store.reportOnSelection()
        #expect(store.reportFocus == .place(SampleData.ID.pumaLosFiltros, .gas))
        store.select(.area("outage.water.guaynabo-frailes", .water))
        store.reportOnSelection()
        #expect(store.reportFocus == .area("outage.water.guaynabo-frailes"))
    }

    @Test("A standing vote can be reopened once, and a new selection forgets that")
    func reviseVote() {
        let store = HomeStore()
        store.select(.place(SampleData.ID.pumaLosFiltros, .gas))
        store.reviseVote()
        #expect(store.isRevisingVote)
        #expect(store.confirmStep == .asking)
        store.select(.place(SampleData.ID.totalSanturce, .gas))
        #expect(!store.isRevisingVote)
    }

    @Test("Older reports and crisis everyday layers open once per visit")
    func reveals() {
        let store = HomeStore()
        store.revealStale(.cheapestGas)
        store.expandEveryday()
        #expect(store.revealedStale == [.cheapestGas])
        #expect(store.isEverydayExpanded)
    }
}
