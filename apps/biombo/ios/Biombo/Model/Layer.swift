import Foundation

/// One of the seven map layers the Capas menu lists (PRODUCT.md §3, §6).
///
/// Fuel and generator availability is not a layer: it is the "Disponibilidad"
/// mode of `.gas` (§6.5), so its report kinds belong to `.gas`.
nonisolated enum Layer: String, CaseIterable, Codable, Hashable, Sendable {
    case power
    case water
    case signal
    case roads
    case gas
    case chargers
    case businesses

    /// The Capas group a layer sits in. In crisis, `.services` comes first and
    /// `.everyday` collapses to one row (§8).
    nonisolated enum Group: String, CaseIterable, Codable, Sendable {
        /// "Servicios": Luz, Agua, Señal, Carreteras.
        case services
        /// "Del día a día": Gasolina, Cargadores, Negocios.
        case everyday
    }

    var group: Group {
        switch self {
        case .power, .water, .signal, .roads: .services
        case .gas, .chargers, .businesses: .everyday
        }
    }

    /// Stations, chargers and businesses are places with a trailing answer;
    /// the other layers speak in event sentences (PRODUCT.md §3).
    var readsAsPlace: Bool { group == .everyday }

    /// Layers whose outages aggregate into affected-area polygons (§7).
    var aggregatesIntoAreas: Bool {
        switch self {
        case .power, .water, .signal: true
        case .roads, .gas, .chargers, .businesses: false
        }
    }

    /// On by default when the user watches a place (§9).
    var isWatchedByDefault: Bool {
        switch self {
        case .power, .water, .roads: true
        case .signal, .gas, .chargers, .businesses: false
        }
    }

    /// Drawn on first launch, before the user touches Capas (*proposed*):
    /// the services that answer "is anything wrong near me" plus gas.
    var isShownByDefault: Bool {
        switch self {
        case .power, .water, .roads, .gas: true
        case .signal, .chargers, .businesses: false
        }
    }

    /// The layers drawn before the user touches Capas. Crisis draws every
    /// service plus gas, which switches to availability (§8).
    static func defaultVisible(inCrisis isCrisis: Bool) -> Set<Layer> {
        Set(allCases.filter { isCrisis ? $0.group == .services || $0 == .gas : $0.isShownByDefault })
    }
}
