import SwiftUI

extension LiveAnswer {
    /// A Capas row's secondary line ("3 apagones cerca", "Nada nuevo").
    func text(unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        switch self {
        case .nothingNew:
            LocalizedStringResource("Nada nuevo", comment: "Capas mini-answer: nothing current on this layer nearby")
        case .powerOutages(let count):
            LocalizedStringResource("\(count) apagones cerca", comment: "Capas mini-answer: power outage areas nearby")
        case .waterOutages(let count):
            LocalizedStringResource("\(count) áreas sin agua cerca", comment: "Capas mini-answer: areas without water nearby")
        case .boilWater:
            LocalizedStringResource("Aviso de hervir el agua", comment: "Capas mini-answer: an official boil-water notice is active nearby")
        case .signalOutages(let count):
            LocalizedStringResource("\(count) áreas sin señal cerca", comment: "Capas mini-answer: areas without cell signal nearby")
        case .roadEvent(let answer):
            answer.eventSentence
        case .roadEvents(let count):
            Layer.roads.countText(count)
        case .noRoadProblems:
            RoadCopy.noProblems
        case .gasFrom(let price):
            LocalizedStringResource("Desde \(unit.perUnit(GlanceNumbers.price(price, unit: unit, locale: locale))) cerca", comment: "Capas mini-answer: the cheapest gas nearby, e.g. 'Desde $0.97/L cerca'")
        case .chargersWorking(let count):
            LocalizedStringResource("\(count) funcionan cerca", comment: "Capas mini-answer: working EV chargers nearby")
        case .openNow(let count):
            LocalizedStringResource("\(count) abiertos ahora", comment: "Capas mini-answer: businesses open now nearby")
        }
    }
}

/// Roads never read as safe (§6.6): with no problem reports, this is all
/// Biombo says. Never "pasable", "segura", "se puede pasar" or "despejada".
nonisolated enum RoadCopy {
    static let noProblems = LocalizedStringResource("Sin reportes de problemas", comment: "Road answer when nothing is reported; never says the road is safe")
}

extension Layer {
    /// How a counted cluster of this layer's pins reads ("6 gasolineras").
    func countText(_ count: Int) -> LocalizedStringResource {
        switch self {
        case .gas: LocalizedStringResource("\(count) gasolineras", comment: "Cluster of gas station pins")
        case .power: LocalizedStringResource("\(count) reportes de luz", comment: "Cluster of power report pins")
        case .water: LocalizedStringResource("\(count) reportes de agua", comment: "Cluster of water report pins")
        case .signal: LocalizedStringResource("\(count) reportes de señal", comment: "Cluster of cell signal report pins")
        case .roads: LocalizedStringResource("\(count) avisos en la carretera", comment: "Road events: a count of reported road problems")
        case .chargers: LocalizedStringResource("\(count) cargadores", comment: "Cluster of EV charger pins")
        case .businesses: LocalizedStringResource("\(count) negocios", comment: "Cluster of business pins")
        }
    }

    /// "2 áreas sin luz": what island zoom says per municipio (§7).
    func areaCountText(_ count: Int) -> LocalizedStringResource {
        switch self {
        case .water: LocalizedStringResource("\(count) áreas sin agua", comment: "Island zoom: areas without water in a municipio")
        case .signal: LocalizedStringResource("\(count) áreas sin señal", comment: "Island zoom: areas without signal in a municipio")
        default: LocalizedStringResource("\(count) áreas sin luz", comment: "Island zoom: areas without power in a municipio")
        }
    }

    var edge: ColorResource {
        switch self {
        case .power: .layerPowerEdge
        case .water: .layerWaterEdge
        case .signal: .layerSignalEdge
        case .roads: .layerRoadsEdge
        case .gas: .layerGasEdge
        case .chargers: .layerEvEdge
        case .businesses: .layerBusinessEdge
        }
    }
}

extension NearbySection.Kind {
    var title: LocalizedStringResource {
        switch self {
        case .cheapestGas: LocalizedStringResource("Más baratas cerca", comment: "Section title: the cheapest gas stations nearby")
        case .services: LocalizedStringResource("Luz, agua y señal", comment: "Section title: power, water and signal near you")
        case .roads: LocalizedStringResource("En la carretera", comment: "Section title: road events near you")
        case .chargers: LocalizedStringResource("Cargadores cerca", comment: "Section title: EV chargers near you")
        case .openNow: LocalizedStringResource("Abiertos ahora", comment: "Section title: businesses open now near you")
        }
    }
}

extension [Layer] {
    /// The Capas title answer: which layers have news, joined as a native list.
    func newsSentence(locale: Locale) -> LocalizedStringResource {
        guard !isEmpty else {
            return LocalizedStringResource("Nada nuevo cerca en las capas que ves", comment: "Capas title answer: no news on the visible layers")
        }
        let names = map { $0.title.string(in: locale) }
            .formatted(.list(type: .and).locale(locale))
        return LocalizedStringResource("Novedades en \(names)", comment: "Capas title answer: the layers with news nearby, as a list")
    }
}
