/// A push inside the home sheet.
enum SheetRoute: Hashable {
    /// "Ver todas (N)": a whole Cerca de ti section.
    case section(NearbySection.Kind)
    /// "Detalles de…" for the current selection.
    case depth
    /// "Gasolina y planta" (§6.5).
    case availability
    /// Why crisis mode is on and what it changes (§8).
    case crisis
    /// The connection and the reports waiting for it (§4.6).
    case outbox
}

/// A sheet over the home sheet that isn't a push: the owner's flows and Tu aporte.
enum HomeModal: Identifiable, Hashable {
    /// "¿Es tu negocio?" (§5 owner verification).
    case claim(Place.ID)
    /// "Publicar como dueño" (§6.8).
    case ownerPost(Place.ID)
    /// "Tu aporte" (§10).
    case contribution

    var id: Self { self }
}
