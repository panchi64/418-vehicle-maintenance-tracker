import SwiftUI

/// How a report kind reads as something to report (PRODUCT.md §6 "Report"
/// lists): the one-tap verb in Quick Report. `word` (ReportKind+Appearance)
/// is how the same kind reads as an answer.
extension ReportKind {
    var verb: LocalizedStringResource {
        switch self {
        case .price: LocalizedStringResource("Reportar el precio", comment: "Quick Report verb: type the pump price")
        case .stationClosed: LocalizedStringResource("Estación cerrada", comment: "Quick Report verb: the station is closed or gone")
        case .hasGas: LocalizedStringResource("Hay gasolina", comment: "Quick Report verb: the station has gas")
        case .noGas: LocalizedStringResource("No hay gasolina", comment: "Quick Report verb: the station is out of gas")
        case .hasDiesel: LocalizedStringResource("Hay diésel", comment: "Quick Report verb: the station has diesel")
        case .noDiesel: LocalizedStringResource("No hay diésel", comment: "Quick Report verb: the station is out of diesel")
        case .queue: LocalizedStringResource("Hay fila", comment: "Quick Report verb: there is a line")
        case .cashOnly: LocalizedStringResource("Solo efectivo", comment: "Quick Report verb: cash only")
        case .perPersonLimit: LocalizedStringResource("Límite por persona", comment: "Quick Report verb: a per-person limit")
        case .openOnGenerator: LocalizedStringResource("Abierto con planta", comment: "Quick Report verb: open on a generator")
        case .hasIce: LocalizedStringResource("Hay hielo", comment: "Quick Report verb: ice for sale")
        case .hasCookingGas: LocalizedStringResource("Hay gas de cocinar", comment: "Quick Report verb: cooking gas for sale")

        case .noPower: LocalizedStringResource("No hay luz aquí", comment: "Quick Report verb: no power where you are")
        case .powerBack: LocalizedStringResource("Volvió la luz", comment: "Quick Report verb: the power came back")
        case .unstablePower: LocalizedStringResource("Luz bajita / va y viene", comment: "Quick Report verb: weak or flickering power")
        case .lineDown: LocalizedStringResource("Poste o cable caído", comment: "Quick Report verb: a pole or power line is down")
        case .transformerBlew: LocalizedStringResource("Transformador explotó", comment: "Quick Report verb: a transformer blew")

        case .noWater: LocalizedStringResource("No hay agua aquí", comment: "Quick Report verb: no water where you are")
        case .waterBack: LocalizedStringResource("Volvió el agua", comment: "Quick Report verb: the water came back")
        case .lowPressure: LocalizedStringResource("Baja presión", comment: "Quick Report verb: low water pressure")
        case .cloudyWater: LocalizedStringResource("Agua turbia", comment: "Quick Report verb: the water is cloudy")
        case .sawBoilNotice: LocalizedStringResource("Vi un aviso de hervir", comment: "Quick Report verb: I saw a boil-water notice")
        case .waterPoint: LocalizedStringResource("Oasis o camión cisterna aquí", comment: "Quick Report verb: water is handed out here")
        case .brokenPipe: LocalizedStringResource("Tubo roto", comment: "Quick Report verb: a broken water pipe")

        case .noSignal: LocalizedStringResource("No hay señal aquí", comment: "Quick Report verb: no cell signal where you are")
        case .callsOnly: LocalizedStringResource("Solo llamadas o SMS", comment: "Quick Report verb: calls and texts only")
        case .hasData: LocalizedStringResource("Hay datos", comment: "Quick Report verb: mobile data works")
        case .signalSpot: LocalizedStringResource("Punto de señal aquí", comment: "Quick Report verb: signal works at this spot")

        case .flooded: LocalizedStringResource("Inundada", comment: "Quick Report verb: the road is flooded")
        case .landslide: LocalizedStringResource("Derrumbe", comment: "Quick Report verb: a landslide")
        case .closed: LocalizedStringResource("Cerrada", comment: "Quick Report verb: the road is closed")
        case .oneLane: LocalizedStringResource("Un carril", comment: "Quick Report verb: one lane open")
        case .highClearanceOnly: LocalizedStringResource("Solo vehículos altos", comment: "Quick Report verb: high-clearance vehicles only")
        case .treeOrPole: LocalizedStringResource("Árbol o poste", comment: "Quick Report verb: a tree or pole on the road")
        case .pothole: LocalizedStringResource("Hoyo peligroso", comment: "Quick Report verb: a dangerous pothole")
        case .reopened: LocalizedStringResource("Abierta otra vez", comment: "Quick Report verb: the road is open again; never says it is safe")

        case .chargerWorks: LocalizedStringResource("Funciona", comment: "Quick Report verb: the charger works")
        case .chargerBroken: LocalizedStringResource("No funciona", comment: "Quick Report verb: the charger is broken")
        case .slowCharging: LocalizedStringResource("Carga lenta", comment: "Quick Report verb: the charger is slow")
        case .connectorDamaged: LocalizedStringResource("Conector dañado", comment: "Quick Report verb: a connector is damaged")
        case .chargerBusy: LocalizedStringResource("Ocupado o hay fila", comment: "Quick Report verb: the charger is busy")
        case .chargerBlocked: LocalizedStringResource("Bloqueado por un carro que no carga", comment: "Quick Report verb: a car that isn't charging blocks it")
        case .needsAppOrCard: LocalizedStringResource("Pide app o tarjeta", comment: "Quick Report verb: needs an app or card")
        case .newCharger: LocalizedStringResource("Cargador nuevo aquí", comment: "Quick Report verb: a new charger here")

        case .businessOpen: LocalizedStringResource("Está abierto", comment: "Quick Report verb: the business is open")
        case .businessClosed: LocalizedStringResource("Está cerrado", comment: "Quick Report verb: the business is closed")
        case .businessOnGenerator: LocalizedStringResource("Tiene planta", comment: "Quick Report verb: the business runs on a generator")
        case .productAvailable, .event, .specialHours: word
        }
    }
}

extension ReportReceipt {
    /// The sent state's one sentence (§4.2). A price says the price.
    func sentence(unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        if let price, delivery == .sent || delivery == .queued {
            let amount = GlanceNumbers.price(price, unit: unit, locale: locale)
            return delivery == .sent
                ? LocalizedStringResource("Listo. Tus vecinos ya ven \(amount) en \(placeName).", comment: "Price sent: neighbours now see the price at the station")
                : LocalizedStringResource("Guardado. El precio de \(amount) en \(placeName) se enviará cuando haya señal.", comment: "Price saved offline: it goes out when signal returns")
        }
        return switch delivery {
        case .sent where isAloneForNow:
            LocalizedStringResource("Listo. Contamos tu “\(kind.verb)” en \(placeName).", comment: "Report sent: a lone outage report is counted, not yet drawn")
        case .sent:
            LocalizedStringResource("Listo. Tus vecinos ya ven “\(kind.verb)” en \(placeName).", comment: "Report sent: neighbours now see it, with the report and the place")
        case .queued:
            LocalizedStringResource("Guardado. “\(kind.verb)” en \(placeName) se enviará cuando haya señal.", comment: "Report saved offline: it goes out when signal returns")
        case .confirmed(let neighbours):
            LocalizedStringResource("Listo. Contándote, lo confirman \(neighbours) vecinos en \(placeName).", comment: "Report matched neighbours' report and counted as a confirmation: how many confirm it now, you included; plural by count")
        case .alreadySaid:
            LocalizedStringResource("Ya lo reportaste hace un momento. No enviamos nada nuevo.", comment: "The same report was sent moments ago; nothing new went out")
        case .heldForReview:
            LocalizedStringResource("Gracias. Revisamos ese precio antes de mostrarlo.", comment: "A price far from DACO's range is held for review")
        }
    }
}
