import SwiftUI

/// The home sheet. Its detents are the disclosure tiers (PRODUCT.md §3): peek
/// shows the search field and one answer; summary adds the postcard line and
/// what comes under the answer; full adds the rest, and depth is a push.
/// With a selection the sheet is that place's or area's detail; otherwise it
/// answers for the area. Only the search field is pinned: the answer scrolls
/// with the content, so large text never leaves a keyhole to read through.
/// Peek is measured to end at the answer's trust line, and never grows past
/// `maxPeek`, so the map controls stay uncovered; a capped peek scrolls.
struct HomeSheet: View {
    @Bindable var store: HomeStore
    let digest: HomeDigest
    let snapshot: PlacesSnapshot
    /// The selection's detail, derived once by `HomeView`.
    let detail: PlaceDetail?
    /// The watched places' news, derived once by `HomeView` beside the digest.
    let watchOverview: WatchOverview
    let connection: ConnectionState
    /// Quick Report's context and its doors, derived by `HomeView`.
    let report: QuickReportInput
    let maxPeek: CGFloat
    @Binding var peekHeight: CGFloat
    /// Select something and move the camera to it.
    let onSelect: (Selection, GeoPoint) -> Void
    /// Move the camera without selecting (municipio results).
    let onFrame: (GeoPoint, Double) -> Void

    @State private var searchHeight: CGFloat = 0
    @State private var leadHeight: CGFloat = 0
    @State private var scroll = ScrollPosition(edge: .top)
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.locale) private var locale
    @Environment(WatchStore.self) private var watches
    @Environment(ContributionStore.self) private var contributions

    var body: some View {
        let detail = store.mode == .nearby ? detail : nil
        NavigationStack(path: $store.path) {
            VStack(spacing: 0) {
                SearchField(store: store)
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.top, Spacing.s5)
                    .padding(.bottom, Spacing.s4)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                        searchHeight = height
                        updatePeek()
                    }
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s6) {
                        lead(detail)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                                leadHeight = height
                                updatePeek()
                            }
                        // Below the answer only from summary up, so peek never shows a half section.
                        content(detail, watchSummary: watchOverview.summary)
                            .opacity(store.tier == .peek ? 0 : 1)
                            .accessibilityHidden(store.tier == .peek)
                    }
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.bottom, Spacing.s8)
                }
                .scrollPosition($scroll)
                .scrollDisabled(store.tier == .peek && !isPeekCapped)
                .scrollDismissesKeyboard(.immediately)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SheetRoute.self) { route in
                SheetDestination(
                    route: route, digest: digest, snapshot: snapshot, detail: detail, connection: connection,
                    onPick: pick, onReport: report.reportHere
                )
            }
            .background(contrast == .increased ? Color(.paperSheet) : .clear)
        }
        .onChange(of: store.tier) { _, tier in
            if tier == .peek { scroll.scrollTo(edge: .top) }
            updatePeek()
        }
        .onChange(of: maxPeek) { updatePeek() }
        .onChange(of: store.selection) { scroll.scrollTo(edge: .top) }
        .homeModals(store: store, snapshot: snapshot, watchOverview: watchOverview, now: digest.now)
    }

    /// What answers first: Quick Report, a selection, or the area's answer.
    @ViewBuilder
    private func lead(_ detail: PlaceDetail?) -> some View {
        switch store.mode {
        case .searching:
            EmptyView()
        case .reporting:
            QuickReportView(
                flow: report.flow, context: report.context, candidates: report.candidates,
                onSend: report.onSend, onDetail: report.onDetail, onClose: store.endReport
            )
        case .nearby:
            if let detail {
                PlaceDetailLead(
                    detail: detail, tier: store.tier,
                    owner: .for(detail, contributions: contributions, open: { store.open($0) }),
                    onReport: report.reportOnSelection, onClose: store.clearSelection
                )
            } else {
                // The app's state (crisis, connection) is a pill over the map, so the answer comes first.
                AreaAnswerView(nearby: digest.nearby, now: digest.now, tier: store.tier)
            }
        }
    }

    @ViewBuilder
    private func content(_ detail: PlaceDetail?, watchSummary summary: WatchSummary) -> some View {
        switch store.mode {
        case .searching:
            SearchResultsView(query: store.query, places: snapshot.places, digest: digest, isPickingWatch: store.searchPurpose == .watch, onChoose: choose)
        case .reporting:
            EmptyView()
        case .nearby:
            if let detail, let selection = store.selection {
                SelectionContent(store: store, detail: detail, snapshot: snapshot, onReport: report.reportOnSelection, onReportPrice: report.reportPrice)
                    .id(selection)
            } else {
                NearbyContent(
                    digest: digest,
                    tier: store.tier == .peek ? .summary : store.tier,
                    revealedStale: store.revealedStale,
                    watchLine: summary.isEmpty ? nil : summary.headline(locale: locale),
                    onReveal: store.revealStale,
                    onPick: pick,
                    onOpenWatchList: store.openWatchList,
                    onReport: report.reportHere
                )
            }
        }
    }

    private func pick(_ item: NearbyItem) {
        onSelect(item.selection, item.anchor)
    }

    /// A place opens its detail even with nothing current, so its empty state
    /// can ask; a barrio with an open outage opens the outage. Picking a
    /// place to watch opens its setup instead (an existing watch to edit).
    private func choose(_ result: PlaceSearch.Result) {
        if store.searchPurpose == .watch {
            let draft: WatchedPlace = switch result {
            case .municipio(let name, let anchor): .draft(municipio: name, at: anchor)
            case .place(let place): .draft(for: place)
            }
            store.chooseToWatch(watches.existing(like: draft) ?? draft)
            return
        }
        switch result {
        case .municipio(_, let anchor):
            store.endSearch()
            onFrame(anchor, HomeCamera.municipioSpan)
        case .place(let place):
            onSelect(digest.selection(forSearched: place), place.anchor)
        }
    }

    private var measuredPeek: CGFloat { searchHeight + leadHeight + Spacing.s4 }
    private var isPeekCapped: Bool { measuredPeek > maxPeek }

    /// Peek follows its measured content at any text size, up to `maxPeek`,
    /// and only changes while at peek.
    private func updatePeek() {
        guard store.tier == .peek, searchHeight > 0 else { return }
        peekHeight = min(measuredPeek, maxPeek)
    }
}
