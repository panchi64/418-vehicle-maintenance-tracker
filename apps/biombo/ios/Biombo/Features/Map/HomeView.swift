import Combine
import MapKit
import SwiftUI
import UIKit

/// Home: the full-bleed map, the glass control stack, Capas over the map and
/// the persistent sheet whose detents are the disclosure tiers. The digest is
/// derived here, kept in state and rebuilt only when the snapshot or the drawn
/// layers change, then handed to all three so they always agree. The
/// selection's detail is kept beside it, rebuilt when the selection or the
/// snapshot changes, never on a sheet layout pass.
struct HomeView: View {
    let snapshot: PlacesSnapshot
    let connection: ConnectionState

    @State private var store: HomeStore
    @State private var digest: HomeDigest
    @State private var detail: PlaceDetail?
    /// The watched places' news, rebuilt with the digest or the watch list.
    @State private var watchOverview = WatchOverview(sharedWarnings: [], statuses: [])
    @State private var camera: MapCameraPosition
    @State private var peekHeight: CGFloat = 200
    /// The screen's bottom and the control stack's, so peek never covers the controls.
    @State private var screenBottom: CGFloat = 0
    @State private var controlsBottom: CGFloat = 0
    @State private var isKeyboardUp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(WatchStore.self) private var watches
    @Environment(DeviceStore.self) private var device
    @Environment(ContributionStore.self) private var contributions
    @Environment(AppRouter.self) private var router
    /// Onboarding's choice, then Capas'; crisis never overwrites it.
    @AppStorage(LayerChoice.storageKey) private var layerChoice: LayerChoice?
    @State private var flow = ReportFlow()

    init(snapshot: PlacesSnapshot, connection: ConnectionState, chosenLayers: Set<Layer>? = nil) {
        self.snapshot = snapshot
        self.connection = connection
        let store = HomeStore(isCrisis: snapshot.crisis.isActive, chosen: chosenLayers)
        _store = State(initialValue: store)
        _digest = State(initialValue: HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: store.visibleLayers))
        _camera = State(initialValue: HomeCamera.around(snapshot.vantage, span: HomeCamera.nearbySpan))
    }

    var body: some View {
        let reporting = HomeReporting(
            store: store, flow: flow, snapshot: snapshot, areas: digest.areas,
            connection: connection, contributions: contributions, device: device
        )
        ZStack(alignment: .topTrailing) {
            HomeMap(
                digest: digest,
                selectedID: store.selectedID,
                camera: $camera,
                onSelect: pick,
                onFrame: frame
            )
            .ignoresSafeArea()
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { screenBottom = $0 }

            // Under Capas, which draws over it while open.
            sentToast(reporting)

            if store.isCapasOpen {
                capas
            } else {
                MapControls(
                    quickReports: reporting.quickReports,
                    onCapas: { animate { store.openCapas() } },
                    onLocate: locate,
                    onReport: reporting.reportHere,
                    onQuickReport: reporting.quickReport
                )
                    .padding(.trailing, Spacing.s3)
                    .padding(.top, Spacing.s2)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { controlsBottom = $0 }
            }
        }
        .overlay(alignment: .topLeading) {
            if !store.isCapasOpen {
                StatusPills(
                    isCrisis: digest.isCrisis,
                    connection: connection,
                    pending: device.outbox.pending(now: connection.now).count,
                    onOpen: { route in animate { store.show(route) } }
                )
                .padding(.leading, Spacing.s3)
                .padding(.top, Spacing.s2)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardUp = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            isKeyboardUp = false
        }
        .onChange(of: store.visibleLayers) { _, layers in
            digest = digest.showing(layers)
            if !digest.isCrisis { layerChoice = LayerChoice(layers) }
        }
        .onChange(of: router.pending, initial: true) {
            if let route = router.take() { HomeRouting(store: store, reporting: reporting).open(route) }
        }
        .widgetPublishing(digest: digest, watchOverview: watchOverview)
        .onChange(of: snapshot) { old, snapshot in
            if old.crisis.isActive != snapshot.crisis.isActive {
                store.applyCrisis(snapshot.crisis.isActive, chosen: layerChoice?.layers)
            }
            digest = HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: store.visibleLayers)
            rebuildDetail()
            rebuildWatchOverview()
        }
        .onChange(of: watches.places, initial: true) { rebuildWatchOverview() }
        .onChange(of: store.selection) { rebuildDetail() }
        .sheet(isPresented: .constant(true)) {
            HomeSheet(
                store: store,
                digest: digest,
                snapshot: snapshot,
                detail: detail,
                watchOverview: watchOverview,
                connection: connection,
                report: reporting.input,
                maxPeek: maxPeek,
                peekHeight: $peekHeight,
                onSelect: select,
                onFrame: frame
            )
            .presentationDetents([.height(peekHeight), .medium, .large], selection: detent)
            // A tall peek (Quick Report) sits above medium; it must stay undimmed and
            // interactive too, or the first tap snaps the sheet instead of sending.
            .presentationBackgroundInteraction(.enabled(upThrough: peekHeight > screenBottom / 2 ? .height(peekHeight) : .medium))
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
    }

    /// The sent state over the map, just above the sheet at peek. It waits
    /// while the keyboard is up: the sheet is still settling from the price
    /// field then, and would cover Deshacer for part of its window.
    @ViewBuilder
    private func sentToast(_ reporting: HomeReporting) -> some View {
        if let receipt = flow.receipt, !isKeyboardUp {
            SentToast(
                receipt: receipt,
                onUndo: { animate { reporting.undo(receipt) } },
                onAddDetail: { animate { reporting.openDetail() } },
                onClose: { animate { flow.dismissReceipt() } }
            )
            .padding(.horizontal, Spacing.s3)
            .padding(.bottom, peekHeight + Spacing.s3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// Capas over the map, closed by tapping anywhere outside it.
    private var capas: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .contentShape(.rect)
                .onTapGesture { animate { store.closeCapas() } }
                .accessibilityHidden(true)
            CapasMenu(
                layers: digest.layers,
                visibleLayers: store.visibleLayers,
                isCrisis: digest.isCrisis,
                isEverydayExpanded: store.isEverydayExpanded,
                onToggle: store.toggle,
                onExpandEveryday: store.expandEveryday,
                onWatchList: store.openWatchList,
                onContribution: { store.open(.contribution) },
                onSettings: store.openSettings
            )
            .padding(.horizontal, Spacing.s3)
            .padding(.top, Spacing.s2)
            .padding(.bottom, peekHeight + Spacing.s3)
            .accessibilityAction(.escape) { animate { store.closeCapas() } }
            .transition(AnyTransition.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.9, anchor: .topTrailing)))
        }
    }

    /// The tier ↔ detent mapping; peek's height follows its measured content.
    private var detent: Binding<PresentationDetent> {
        Binding(
            get: {
                switch store.tier {
                case .peek: .height(peekHeight)
                case .summary: .medium
                case .full: .large
                }
            },
            set: { detent in
                store.tier = switch detent {
                case .medium: .summary
                case .large: .full
                default: .peek
                }
            }
        )
    }

    /// Peek stops short of the control stack; unmeasured, it is unlimited.
    private var maxPeek: CGFloat {
        guard screenBottom > 0, controlsBottom > 0 else { return .infinity }
        return max(screenBottom - controlsBottom - Spacing.s3, Size.target * 3)
    }

    private func rebuildDetail() {
        detail = store.selection.flatMap { PlaceDetailBuilder().detail(for: $0, snapshot: snapshot, areas: digest.areas) }
    }

    /// Watch news reads the digest's answers and notices, not which layers are drawn.
    private func rebuildWatchOverview() {
        watchOverview = WatchStatusBuilder().overview(for: watches.places, digest: digest)
    }

    private func pick(_ item: NearbyItem) {
        select(item.selection, at: item.anchor)
    }

    private func select(_ selection: Selection, at anchor: GeoPoint) {
        store.select(selection)
        frame(anchor, HomeCamera.placeSpan)
    }

    private func locate() {
        frame(digest.vantage, HomeCamera.nearbySpan)
    }

    private func frame(_ point: GeoPoint, _ span: Double) {
        let target = HomeCamera.around(point, span: max(span, 0.01))
        animate(.easeInOut(duration: 0.45)) { camera = target }
    }

    /// Animates a change unless Reduce Motion is on.
    private func animate(_ animation: Animation = .snappy, _ change: () -> Void) {
        if reduceMotion {
            change()
        } else {
            withAnimation(animation, change)
        }
    }
}
