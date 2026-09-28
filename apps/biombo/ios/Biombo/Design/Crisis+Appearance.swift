import Foundation

/// Crisis mode's words (PRODUCT.md §8): plain copy, one sentence per reason.
extension CrisisState.Trigger {
    /// Why the mode is on, in one sentence.
    var reason: LocalizedStringResource {
        switch self {
        case .nwsWarning:
            LocalizedStringResource("El Servicio Nacional de Meteorología tiene un aviso de tormenta o huracán para Puerto Rico.", comment: "Crisis reason: an NWS hurricane or tropical storm warning")
        case .lumaCustomersOut:
            LocalizedStringResource("LUMA reporta a más de 1 de cada 10 clientes sin luz.", comment: "Crisis reason: LUMA reports over 10% of customers out")
        case .dirsActivated:
            LocalizedStringResource("La FCC activó su sistema de reportes de emergencia para las antenas.", comment: "Crisis reason: the FCC activated DIRS for Puerto Rico")
        case .communityPowerAreas:
            LocalizedStringResource("Vecinos reportan apagones en muchos municipios a la vez.", comment: "Crisis reason: community power outages across many municipios")
        case .declaration:
            LocalizedStringResource("Manejo de Emergencias declaró la emergencia.", comment: "Crisis reason: an authority declared the emergency")
        }
    }

    var symbol: String {
        switch self {
        case .nwsWarning: "hurricane"
        case .lumaCustomersOut, .communityPowerAreas: "bolt.slash"
        case .dirsActivated: "antenna.radiowaves.left.and.right.slash"
        case .declaration: "building.columns"
        }
    }
}

nonisolated enum CrisisCopy {
    static let title = LocalizedStringResource("Modo emergencia", comment: "Crisis banner title")
    /// The small pill over the map that says the mode is on (V2-Crisis).
    static let pillTitle = LocalizedStringResource("Emergencia", comment: "Crisis pill over the map: emergency mode is on")
    static let pillHint = LocalizedStringResource("Se muestra primero lo esencial.", comment: "Crisis banner: essentials are shown first")

    /// What changes while the mode is on, one plain line each.
    static let changes: [(symbol: String, text: LocalizedStringResource)] = [
        ("bolt", LocalizedStringResource("Luz, agua, señal y carreteras van primero.", comment: "Crisis change: utility layers come first")),
        ("fuelpump", LocalizedStringResource("Gasolina muestra dónde hay, no los precios.", comment: "Crisis change: gas shows availability instead of prices")),
        ("list.bullet", LocalizedStringResource("Menos filas por sección y sin promociones.", comment: "Crisis change: tighter row budgets, no promotions")),
        ("map", LocalizedStringResource("El mapa es sencillo, sin dibujos.", comment: "Crisis change: the map is plain, with no art")),
    ]

    /// How the mode turns off: only a declared crisis ends by declaration (§8).
    static func howItEnds(isDeclared: Bool) -> LocalizedStringResource {
        isDeclared
            ? LocalizedStringResource(
                "Se apaga cuando todo lleva 6 horas en calma, o cuando Manejo de Emergencias declare el fin.",
                comment: "Crisis: how the mode turns off"
            )
            : LocalizedStringResource("Se apaga cuando todo lleva 6 horas en calma.", comment: "Crisis: how an automatically triggered mode turns off")
    }
}
