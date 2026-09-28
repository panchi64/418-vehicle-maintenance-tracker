import Observation

/// The home screen's interaction state: which tier the sheet is at, which
/// layers are drawn, what is selected, searched or open. Pure transitions only;
/// the camera, focus and animation belong to the views.
@Observable
final class HomeStore {
    var tier: DisclosureTier = .peek
    private(set) var mode: Mode = .nearby
    private(set) var searchPurpose: SearchPurpose = .find
    private(set) var afterWatchList: AfterWatchList?
    private(set) var visibleLayers: Set<Layer>
    private(set) var isCapasOpen = false
    /// A pin, cluster member, area, row or search result the user picked.
    private(set) var selection: Selection?
    /// The confirm question's progress on this visit to the selection.
    private(set) var confirmStep: ConfirmStep = .asking
    /// "Cambiar" on a standing vote reopens the question once (§4.3).
    private(set) var isRevisingVote = false
    /// What Quick Report is about: where you stand, or the selection.
    private(set) var reportFocus: ReportContext.Focus = .whereYouAre
    /// The owner's flows or Tu aporte, over the sheet.
    var modal: HomeModal?
    /// The watch being set up or edited ("Vigilar"), shown as a sheet (§9).
    var watchDraft: WatchedPlace?
    var isWatchListOpen = false
    var isSettingsOpen = false
    var query = ""
    /// What the sheet has pushed: a whole section, or the selection's depth.
    var path: [SheetRoute] = []
    /// Sections whose "Ver reportes anteriores (N)" was opened this visit (§4.4).
    private(set) var revealedStale: Set<NearbySection.Kind> = []
    /// In crisis, "Del día a día" collapses to one row until the user opens it (§8).
    private(set) var isEverydayExpanded = false

    init(isCrisis: Bool = false, chosen: Set<Layer>? = nil) {
        visibleLayers = Layer.initiallyVisible(inCrisis: isCrisis, chosen: chosen)
    }

    // MARK: - Crisis

    /// Crisis turning on or off resets the drawn layers (§8): every service
    /// in crisis, the user's own choice after it. It folds Del día a día
    /// again, drops a selection whose layer is no longer drawn, and closes
    /// the screens that speak for the mode ("Modo emergencia", "Gasolina y planta").
    func applyCrisis(_ isCrisis: Bool, chosen: Set<Layer>? = nil) {
        visibleLayers = Layer.initiallyVisible(inCrisis: isCrisis, chosen: chosen)
        isEverydayExpanded = false
        path.removeAll { $0 == .crisis || $0 == .availability }
        if let selection, !visibleLayers.contains(selection.layer) { clearSelection() }
    }

    /// A status pill over the map ("Emergencia", "Sin conexión") opens what
    /// it means in the sheet, over whatever the sheet showed.
    func show(_ route: SheetRoute) {
        mode = .nearby
        query = ""
        isCapasOpen = false
        path = [route]
        tier = .full
    }

    // MARK: - Capas

    /// Capas opens over the map, so the sheet drops to peek to keep it in view.
    func openCapas() {
        isCapasOpen = true
        tier = .peek
        mode = .nearby
        query = ""
    }

    func closeCapas() {
        isCapasOpen = false
    }

    /// Hiding the selection's layer ends the selection, so showing it again
    /// never brings back a stale card.
    func toggle(_ layer: Layer) {
        if visibleLayers.contains(layer) {
            visibleLayers.remove(layer)
            if selection?.layer == layer { clearSelection() }
        } else {
            visibleLayers.insert(layer)
        }
    }

    func expandEveryday() {
        isEverydayExpanded = true
    }

    // MARK: - Selection

    /// Picking something opens its detail in the sheet at summary, so the
    /// map still shows where it is. A pick on a hidden layer (from search)
    /// draws that layer, so its pin appears. A new selection asks afresh and
    /// drops any pushed depth; tapping the same pin again keeps the reply.
    func select(_ selection: Selection) {
        if selection != self.selection {
            confirmStep = .asking
            isRevisingVote = false
            path = []
        }
        self.selection = selection
        visibleLayers.insert(selection.layer)
        isCapasOpen = false
        mode = .nearby
        query = ""
        tier = .summary
    }

    var selectedID: String? { selection?.mapID }

    func clearSelection() {
        selection = nil
        confirmStep = .asking
        isRevisingVote = false
        path = []
    }

    // MARK: - Detail

    func reply(_ reply: ConfirmReply, to question: ConfirmQuestion) {
        confirmStep = confirmStep.replying(reply, to: question)
    }

    /// Deshacer, within the view's 5-second window.
    func undoReply() {
        confirmStep = .asking
    }

    /// "Cambiar" under a vote given on an earlier visit: ask again, once.
    func reviseVote() {
        confirmStep = .asking
        isRevisingVote = true
    }

    // MARK: - Watch

    /// "Vigilar" opens the setup sheet for a new or existing watch. From the
    /// list, setup waits until the list has finished closing, since one
    /// sheet can't present while another is dismissing.
    func beginWatch(_ draft: WatchedPlace) {
        if isWatchListOpen {
            afterWatchList = .setup(draft)
            isWatchListOpen = false
        } else {
            watchDraft = draft
        }
    }

    func openWatchList() {
        isCapasOpen = false
        isWatchListOpen = true
    }

    /// "Vigilar otro lugar": a search that says what it is for, whose
    /// result opens setup. From the list, it starts once the list has closed.
    func watchAnother() {
        clearSelection()
        if isWatchListOpen {
            afterWatchList = .findPlaceToWatch
            isWatchListOpen = false
        } else {
            beginSearch(for: .watch)
        }
    }

    /// The watch list finished closing: run what it asked for.
    func watchListDidDismiss() {
        switch afterWatchList {
        case .setup(let draft): watchDraft = draft
        case .findPlaceToWatch: beginSearch(for: .watch)
        case nil: break
        }
        afterWatchList = nil
    }

    /// A search result picked to watch opens its setup.
    func chooseToWatch(_ draft: WatchedPlace) {
        endSearch()
        watchDraft = draft
    }

    func openSettings() {
        isCapasOpen = false
        isSettingsOpen = true
    }

    /// Tu aporte, the owner's claim or post, over the sheet.
    func open(_ modal: HomeModal) {
        isCapasOpen = false
        self.modal = modal
    }

    // MARK: - Search

    func beginSearch(for purpose: SearchPurpose = .find) {
        mode = .searching
        searchPurpose = purpose
        isCapasOpen = false
        tier = .full
    }

    func endSearch() {
        mode = .nearby
        searchPurpose = .find
        query = ""
        tier = .summary
    }

    // MARK: - Reportar

    /// "Reportar aquí": about where you stand. Quick Report sits at peek,
    /// which is measured to fit it.
    func reportHere() {
        beginReport(about: .whereYouAre)
    }

    /// Reportar under a detail: about the selected place or area.
    func reportOnSelection() {
        switch selection {
        case .place(let id, let layer): beginReport(about: .place(id, layer))
        case .area(let id, _): beginReport(about: .area(id))
        case nil: beginReport(about: .whereYouAre)
        }
    }

    private func beginReport(about focus: ReportContext.Focus) {
        reportFocus = focus
        mode = .reporting
        path = []
        isCapasOpen = false
        query = ""
        tier = .peek
    }

    func endReport() {
        mode = .nearby
    }

    // MARK: - Older reports

    func revealStale(_ kind: NearbySection.Kind) {
        revealedStale.insert(kind)
    }
}
