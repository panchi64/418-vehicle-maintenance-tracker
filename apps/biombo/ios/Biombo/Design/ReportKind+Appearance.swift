import SwiftUI

/// How a report kind reads as an answer: the short word a pin label or a
/// place row's trailing value shows, the glyph inside its pin, and the full
/// sentence an event row says. Roads never read as safe (§6.6).
extension ReportKind {
    var word: LocalizedStringResource {
        switch self {
        case .price: LocalizedStringResource("Precio", comment: "Answer word: a pump price was reported")
        case .stationClosed: LocalizedStringResource("Cerrada", comment: "Answer word: the gas station is closed")
        case .hasGas: LocalizedStringResource("Hay gasolina", comment: "Answer word: the station has gas")
        case .noGas: LocalizedStringResource("No hay gasolina", comment: "Answer word: the station is out of gas")
        case .hasDiesel: LocalizedStringResource("Hay diésel", comment: "Answer word: the station has diesel")
        case .noDiesel: LocalizedStringResource("No hay diésel", comment: "Answer word: the station is out of diesel")
        case .queue: LocalizedStringResource("Hay fila", comment: "Answer word: there is a line at the station")
        case .cashOnly: LocalizedStringResource("Solo efectivo", comment: "Answer word: cash only")
        case .perPersonLimit: LocalizedStringResource("Con límite", comment: "Answer word: a per-person limit applies")
        case .openOnGenerator: LocalizedStringResource("Con planta", comment: "Answer word: open on a generator")
        case .hasIce: LocalizedStringResource("Hay hielo", comment: "Answer word: ice is available")
        case .hasCookingGas: LocalizedStringResource("Hay gas", comment: "Answer word: cooking gas is available")

        case .noPower: LocalizedStringResource("Sin luz", comment: "Answer word: no electric power")
        case .powerBack: LocalizedStringResource("Volvió la luz", comment: "Answer word: power came back")
        case .unstablePower: LocalizedStringResource("Va y viene", comment: "Answer word: power keeps going on and off")
        case .lineDown: LocalizedStringResource("Cable caído", comment: "Answer word: a pole or power line is down")
        case .transformerBlew: LocalizedStringResource("Transformador", comment: "Answer word: a transformer blew")

        case .noWater: LocalizedStringResource("Sin agua", comment: "Answer word: no running water")
        case .waterBack: LocalizedStringResource("Volvió el agua", comment: "Answer word: water came back")
        case .lowPressure: LocalizedStringResource("Baja presión", comment: "Answer word: low water pressure")
        case .cloudyWater: LocalizedStringResource("Agua turbia", comment: "Answer word: cloudy water")
        case .sawBoilNotice: LocalizedStringResource("Aviso de hervir", comment: "Answer word: someone saw a boil-water notice")
        case .waterPoint: LocalizedStringResource("Oasis", comment: "Answer word: a water distribution point or tanker")
        case .brokenPipe: LocalizedStringResource("Tubo roto", comment: "Answer word: a broken water pipe")

        case .noSignal: LocalizedStringResource("Sin señal", comment: "Answer word: no cell signal")
        case .callsOnly: LocalizedStringResource("Solo llamadas", comment: "Answer word: calls and texts only, no data")
        case .hasData: LocalizedStringResource("Hay datos", comment: "Answer word: mobile data works")
        case .signalSpot: LocalizedStringResource("Punto de señal", comment: "Answer word: a spot where signal works")

        case .flooded: LocalizedStringResource("Inundada", comment: "Answer word: the road is flooded")
        case .landslide: LocalizedStringResource("Derrumbe", comment: "Answer word: a landslide on the road")
        case .closed: LocalizedStringResource("Cerrada", comment: "Answer word: the road is closed")
        case .oneLane: LocalizedStringResource("Un carril", comment: "Answer word: one lane open")
        case .highClearanceOnly: LocalizedStringResource("Solo 4x4", comment: "Answer word: high-clearance vehicles only")
        case .treeOrPole: LocalizedStringResource("Árbol o poste", comment: "Answer word: a tree or pole on the road")
        case .pothole: LocalizedStringResource("Hoyo", comment: "Answer word: a dangerous pothole")
        case .reopened: LocalizedStringResource("Reportada abierta", comment: "Answer word: people report the road open again; never says it is safe")

        case .chargerWorks: LocalizedStringResource("Funciona", comment: "Answer word: the EV charger works")
        case .chargerBroken: LocalizedStringResource("No funciona", comment: "Answer word: the EV charger is broken")
        case .slowCharging: LocalizedStringResource("Carga lenta", comment: "Answer word: the EV charger is slow")
        case .connectorDamaged: LocalizedStringResource("Conector dañado", comment: "Answer word: a connector is damaged")
        case .chargerBusy: LocalizedStringResource("Ocupado", comment: "Answer word: the EV charger is busy")
        case .chargerBlocked: LocalizedStringResource("Bloqueado", comment: "Answer word: a car that isn't charging blocks the charger")
        case .needsAppOrCard: LocalizedStringResource("Pide app", comment: "Answer word: the charger needs an app or card")
        case .newCharger: LocalizedStringResource("Nuevo", comment: "Answer word: a new charger")

        case .businessOpen: LocalizedStringResource("Abierto", comment: "Answer word: the business is open")
        case .businessClosed: LocalizedStringResource("Cerrado", comment: "Answer word: the business is closed")
        case .businessOnGenerator: LocalizedStringResource("Con planta", comment: "Answer word: open on a generator")
        case .productAvailable: LocalizedStringResource("Hay producto", comment: "Answer word: the owner says a product is in stock")
        case .event: LocalizedStringResource("Evento", comment: "Answer word: an event at the business")
        case .specialHours: LocalizedStringResource("Horario especial", comment: "Answer word: special opening hours")
        }
    }

    /// The glyph inside the pin: the layer's own, or its status variant.
    var glyph: String {
        switch self {
        case .noPower: "bolt.slash.fill"
        case .noGas, .noDiesel, .stationClosed: "fuelpump.slash.fill"
        case .noSignal: "antenna.radiowaves.left.and.right.slash"
        case .flooded: "water.waves"
        case .landslide, .closed, .oneLane, .highClearanceOnly, .treeOrPole, .pothole,
             .lineDown, .transformerBlew, .brokenPipe, .chargerBroken, .connectorDamaged:
            "exclamationmark"
        case .businessClosed: "xmark"
        default: layer.symbol
        }
    }

    /// The sentence an event row says about `name` ("Inundada la PR-52, km 14").
    func eventSentence(at name: String) -> LocalizedStringResource {
        switch self {
        case .flooded: LocalizedStringResource("Inundada la \(name)", comment: "Road event: the named road is flooded")
        case .landslide: LocalizedStringResource("Derrumbe en la \(name)", comment: "Road event: a landslide on the named road")
        case .closed: LocalizedStringResource("Cerrada la \(name)", comment: "Road event: the named road is closed")
        case .oneLane: LocalizedStringResource("Un carril en la \(name)", comment: "Road event: one lane open on the named road")
        case .highClearanceOnly: LocalizedStringResource("Solo vehículos altos en la \(name)", comment: "Road event: high-clearance vehicles only")
        case .treeOrPole: LocalizedStringResource("Árbol o poste en la \(name)", comment: "Road event: a tree or pole on the named road")
        case .pothole: LocalizedStringResource("Hoyo peligroso en la \(name)", comment: "Road event: a dangerous pothole on the named road")
        case .reopened: LocalizedStringResource("Reportada abierta la \(name)", comment: "Road event: people report the named road open again; never says it is safe")
        case .lineDown: LocalizedStringResource("Poste o cable caído en \(name)", comment: "Power event: a pole or line down in the named barrio")
        case .transformerBlew: LocalizedStringResource("Explotó un transformador en \(name)", comment: "Power event: a transformer blew in the named barrio")
        case .unstablePower: LocalizedStringResource("La luz va y viene en \(name)", comment: "Power event: unstable power in the named barrio")
        case .lowPressure: LocalizedStringResource("Baja presión de agua en \(name)", comment: "Water event: low pressure in the named barrio")
        case .cloudyWater: LocalizedStringResource("Agua turbia en \(name)", comment: "Water event: cloudy water in the named barrio")
        case .sawBoilNotice: LocalizedStringResource("Vieron un aviso de hervir en \(name)", comment: "Water event: someone saw a boil-water notice")
        case .waterPoint: LocalizedStringResource("Hay un oasis de agua en \(name)", comment: "Water event: a water distribution point in the named barrio")
        case .brokenPipe: LocalizedStringResource("Tubo roto en \(name)", comment: "Water event: a broken pipe in the named barrio")
        case .signalSpot: LocalizedStringResource("Hay un punto de señal en \(name)", comment: "Signal event: a spot where signal works")
        case .callsOnly: LocalizedStringResource("Solo llamadas en \(name)", comment: "Signal event: calls and texts only")
        default: LocalizedStringResource("\(word) en \(name)", comment: "Generic event: an answer word, then the place it applies to")
        }
    }
}
