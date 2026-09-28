import SwiftUI

/// How domain values look. Status, layer and verification always carry a
/// symbol plus a word, never colour alone (DESIGN.md non-negotiables).
extension Layer {
    var title: LocalizedStringResource {
        switch self {
        case .power: LocalizedStringResource("Luz", comment: "Layer name: electric power")
        case .water: LocalizedStringResource("Agua", comment: "Layer name: running water")
        case .signal: LocalizedStringResource("Señal", comment: "Layer name: cell signal")
        case .roads: LocalizedStringResource("Carreteras", comment: "Layer name: road conditions")
        case .gas: LocalizedStringResource("Gasolina", comment: "Layer name: gas prices and fuel availability")
        case .chargers: LocalizedStringResource("Cargadores", comment: "Layer name: EV chargers")
        case .businesses: LocalizedStringResource("Negocios", comment: "Layer name: businesses and events")
        }
    }

    /// One line on what the layer shows, where the user chooses layers.
    var pitch: LocalizedStringResource {
        switch self {
        case .power: LocalizedStringResource("Apagones y cuándo vuelve", comment: "Layer pitch: power outages and restoration")
        case .water: LocalizedStringResource("Sin servicio y avisos de hervir", comment: "Layer pitch: water outages and boil-water notices")
        case .signal: LocalizedStringResource("Dónde hay y no hay señal", comment: "Layer pitch: where cell signal works")
        case .roads: LocalizedStringResource("Inundaciones, derrumbes y cierres", comment: "Layer pitch: floods, landslides and closures")
        case .gas: LocalizedStringResource("Precios y dónde hay", comment: "Layer pitch: gas prices and availability")
        case .chargers: LocalizedStringResource("Cargadores que funcionan", comment: "Layer pitch: EV chargers that work")
        case .businesses: LocalizedStringResource("Abiertos, con planta y eventos", comment: "Layer pitch: open businesses, on generator, events")
        }
    }

    var symbol: String {
        switch self {
        case .power: "bolt.fill"
        case .water: "drop.fill"
        case .signal: "antenna.radiowaves.left.and.right"
        case .roads: "road.lanes"
        case .gas: "fuelpump.fill"
        case .chargers: "ev.charger.fill"
        case .businesses: "storefront.fill"
        }
    }

    /// The layer's identity wash (pins, Capas marks). Never carries text.
    var wash: ColorResource {
        switch self {
        case .power: .layerPower
        case .water: .layerWater
        case .signal: .layerSignal
        case .roads: .layerRoads
        case .gas: .layerGas
        case .chargers: .layerEv
        case .businesses: .layerBusiness
        }
    }

    /// The glyph ink that reads on `wash`: paper on the deep washes, ink on the pale ones.
    var glyph: ColorResource {
        switch self {
        case .gas, .roads, .water: .layerGlyphDeep
        case .chargers, .businesses, .signal, .power: .layerGlyphPale
        }
    }
}

extension VerificationLabel {
    /// The word shown in rows. Detail adds the neighbour count.
    var title: LocalizedStringResource {
        switch self {
        case .official(let agency):
            LocalizedStringResource("Oficial · \(agency.displayName)", comment: "Verification label: official, then the agency name")
        case .verifiedOwner:
            LocalizedStringResource("Dueño verificado", comment: "Verification label: the verified owner posted this")
        case .communityConfirmed:
            LocalizedStringResource("Confirmado", comment: "Verification label in rows: confirmed by neighbours")
        case .unverified:
            LocalizedStringResource("Sin verificar", comment: "Verification label: nobody has confirmed this yet")
        }
    }

    var symbol: String {
        switch self {
        case .official: "building.columns"
        case .verifiedOwner: "checkmark.seal"
        case .communityConfirmed: "person.2.fill"
        case .unverified: "questionmark.circle"
        }
    }

    var ink: ColorResource {
        switch self {
        case .official: .verifyOfficial
        case .verifiedOwner: .verifyOwner
        case .communityConfirmed: .verifyCommunity
        case .unverified: .verifyUnverified
        }
    }
}
