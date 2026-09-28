import SwiftUI

extension View {
    /// The sheets over the home sheet: Ajustes, watch setup and the watch
    /// list, and the owner's flows and Tu aporte.
    func homeModals(store: HomeStore, snapshot: PlacesSnapshot, watchOverview: WatchOverview, now: Date) -> some View {
        modifier(HomeModals(store: store, snapshot: snapshot, watchOverview: watchOverview, now: now))
    }
}

private struct HomeModals: ViewModifier {
    @Bindable var store: HomeStore
    let snapshot: PlacesSnapshot
    let watchOverview: WatchOverview
    let now: Date

    @Environment(WatchStore.self) private var watches
    @Environment(DeviceStore.self) private var device
    @Environment(ContributionStore.self) private var contributions
    /// "Borrar mis datos" was confirmed: erase once Ajustes has closed, since
    /// erasing replaces home (and every sheet on it) with the first run.
    @State private var erasesOnDismiss = false

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $store.isSettingsOpen, onDismiss: eraseIfConfirmed) {
                SettingsView {
                    erasesOnDismiss = true
                    store.isSettingsOpen = false
                }
            }
            .sheet(item: $store.watchDraft) { draft in
                WatchSetupView(
                    draft: draft,
                    motif: snapshot.places.first { $0.id == draft.placeID }.map { PlateMotif(region: $0.region) },
                    isExisting: watches.places.contains { $0.id == draft.id },
                    canAdd: !watches.isFull,
                    onSave: { watches.save($0) },
                    onRemove: watches.remove
                )
            }
            .sheet(isPresented: $store.isWatchListOpen, onDismiss: store.watchListDidDismiss) {
                WatchListView(overview: watchOverview, now: now, isFull: watches.isFull, onEdit: store.beginWatch, onWatchAnother: store.watchAnother)
            }
            .sheet(item: $store.modal) { modal in
                switch modal {
                case .claim(let id):
                    if let place = place(id) {
                        OwnerClaimView(place: place, distance: snapshot.vantage.distance(to: place.anchor), now: now) {
                            store.modal = .ownerPost(id)
                        }
                    }
                case .ownerPost(let id):
                    if let place = place(id) {
                        OwnerPostView(place: place, now: now)
                    }
                case .contribution:
                    ContributionView(now: now, isCrisis: snapshot.crisis.isActive)
                }
            }
    }

    private func eraseIfConfirmed() {
        guard erasesOnDismiss else { return }
        erasesOnDismiss = false
        let eraser = DataEraser(watches: watches, device: device, contributions: contributions)
        eraser.eraseStoredData()
        eraser.eraseSystemTraces()
    }

    private func place(_ id: Place.ID) -> Place? {
        snapshot.places.first { $0.id == id }
    }
}
