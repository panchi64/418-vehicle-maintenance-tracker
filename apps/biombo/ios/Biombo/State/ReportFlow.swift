import Observation

/// Quick Report's interaction state (PRODUCT.md §4.2, V2-QuickReport): which
/// step is showing, any place picked with Cambiar, and the sent receipt
/// shown over the map. What the report is about is `HomeStore.reportFocus`.
/// Pure transitions; the sending itself is `ReportSender`'s.
@Observable
final class ReportFlow {
    enum Step: Hashable {
        /// The context line, three one-tap verbs and "Otra cosa…".
        case menu
        /// "¿Sobre qué quieres avisar?": the seven layers.
        case layers
        /// One layer's ≤4 verbs and its Más menu.
        case layer(Layer)
        /// A price: grade, amount and an optional sign photo.
        case price(Place.ID)
        /// Cambiar: another place in reach for this layer.
        case place(Layer)
        /// "Añadir detalle" for a report just sent.
        case detail(ReportReceipt)
    }

    private(set) var step: Step = .menu
    /// Places picked with Cambiar, per layer.
    private(set) var chosen: [Layer: Place.ID] = [:]
    /// The sent state over the map; nil when none is showing.
    private(set) var receipt: ReportReceipt?

    /// Quick Report opens on the menu, with nothing picked yet; an earlier
    /// receipt still over the map is done with.
    func begin() {
        step = .menu
        previous = .menu
        chosen = [:]
        receipt = nil
    }

    /// Where Cambiar and a price return to.
    private var previous: Step = .menu

    func show(_ step: Step) {
        previous = self.step
        self.step = step
    }

    /// Back one level: a layer's page returns to the list, Cambiar and a
    /// price to where they were opened from, the list to the menu. Añadir
    /// detalle belongs to a report already sent, so it has no back, only Cerrar.
    func back() {
        switch step {
        case .layer: step = .layers
        case .place, .price: step = previous
        case .layers: step = .menu
        case .menu, .detail: break
        }
    }

    var canGoBack: Bool {
        switch step {
        case .menu, .detail: false
        case .layers, .layer, .price, .place: true
        }
    }

    func choose(_ placeID: Place.ID, for layer: Layer) {
        chosen[layer] = placeID
        step = previous
    }

    // MARK: - Receipt

    func sent(_ receipt: ReportReceipt) {
        self.receipt = receipt
        step = .menu
    }

    /// "Añadir detalle" reopens Quick Report on the detail for this receipt.
    /// Opened this way, Quick Report doesn't `begin()`.
    func addDetail() {
        guard let receipt else { return }
        step = .detail(receipt)
        self.receipt = nil
    }

    func dismissReceipt() {
        receipt = nil
    }
}
