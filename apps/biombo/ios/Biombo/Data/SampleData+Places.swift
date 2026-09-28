import Foundation

/// SAMPLE DATA — invented places across the metro, central and western regions.
/// Names are fictional where they would stand for a real business.
nonisolated extension SampleData {
    nonisolated enum ID {
        static let pumaLosFiltros = "station.puma-los-filtros"
        static let totalSanturce = "station.total-santurce"
        static let shellRioPiedras = "station.shell-rio-piedras"
        static let gulfBairoa = "station.gulf-bairoa"
        static let pumaCayey = "station.puma-cayey"
        static let texacoMayaguez = "station.texaco-mayaguez"
        static let shellAguadilla = "station.shell-aguadilla"
        static let totalCaboRojo = "station.total-cabo-rojo"

        static let chargerPlazaAmericas = "charger.plaza-las-americas"
        static let chargerCaguasCentro = "charger.caguas-centro"
        static let chargerMayaguezMall = "charger.mayaguez-mall"

        static let panaderiaLaCeiba = "business.panaderia-la-ceiba"
        static let farmaciaDelPueblo = "business.farmacia-del-pueblo"
        static let colmadoDonaCarmen = "business.colmado-dona-carmen"

        static let pr52Caguas = "road.pr-52-km-14"
        static let pr156Comerio = "road.pr-156-km-31"
        static let pr2Mayaguez = "road.pr-2-km-156"
        static let pr115Rincon = "road.pr-115-km-12"

        static let bairoa = "area.caguas.bairoa"
        static let rioPiedras = "area.san-juan.rio-piedras"
        static let miradero = "area.mayaguez.miradero"
        static let comerioPueblo = "area.comerio.pueblo"
        static let puebloViejo = "area.guaynabo.pueblo-viejo"
        static let frailes = "area.guaynabo.frailes"
        static let shellCidra = "station.shell-cidra"
        static let losPaseos = "station.los-paseos"
    }

    nonisolated static let places: [Place] = stations + chargers + businesses + roads + areas

    nonisolated static let stations: [Place] = [
        station(ID.pumaLosFiltros, "Puma Los Filtros", brand: "Puma", "Guaynabo", "Frailes", .metro, 18.3747, -66.1197),
        station(ID.totalSanturce, "Total Santurce", brand: "Total", "San Juan", "Santurce", .metro, 18.4460, -66.0600),
        station(ID.shellRioPiedras, "Shell Río Piedras", brand: "Shell", "San Juan", "Río Piedras", .metro, 18.3990, -66.0500),
        station(ID.gulfBairoa, "Gulf Bairoa", brand: "Gulf", "Caguas", "Bairoa", .central, 18.2505, -66.0445),
        station(ID.pumaCayey, "Puma Cayey", brand: "Puma", "Cayey", "Montellano", .central, 18.1120, -66.1660),
        station(ID.texacoMayaguez, "Texaco Mayagüez", brand: "Texaco", "Mayagüez", "Miradero", .west, 18.2150, -67.1420),
        station(ID.shellAguadilla, "Shell Aguadilla", brand: "Shell", "Aguadilla", "Victoria", .west, 18.4275, -67.1541),
        station(ID.totalCaboRojo, "Total Cabo Rojo", brand: "Total", "Cabo Rojo", "Pueblo", .west, 18.0866, -67.1457),
        // Only older reports: the empty state with "Ver reportes anteriores".
        station(ID.shellCidra, "Shell Cidra", brand: "Shell", "Cidra", "Rincón", .central, 18.1760, -66.1610),
        // Off DACO's brand list: compared against DACO's island range.
        station(ID.losPaseos, "Estación Los Paseos", brand: nil, "San Juan", "Cupey", .metro, 18.3790, -66.0620),
    ]

    nonisolated static let chargers: [Place] = [
        point(ID.chargerPlazaAmericas, .charger, "Cargador Plaza Las Américas", "San Juan", "Hato Rey", .metro, 18.4220, -66.0730,
              ports: [ChargerPort(connector: .ccs1, kilowatts: 50, count: 2), ChargerPort(connector: .j1772, kilowatts: 7, count: 2)]),
        point(ID.chargerCaguasCentro, .charger, "Cargador Plaza Centro", "Caguas", "Bairoa", .central, 18.2380, -66.0330,
              ports: [ChargerPort(connector: .j1772, kilowatts: 7, count: 2)]),
        point(ID.chargerMayaguezMall, .charger, "Cargador Mayagüez Mall", "Mayagüez", "Sabalos", .west, 18.1830, -67.1480,
              ports: [ChargerPort(connector: .ccs1, kilowatts: 50), ChargerPort(connector: .chademo, kilowatts: 50)]),
    ]

    nonisolated static let businesses: [Place] = [
        point(ID.panaderiaLaCeiba, .business, "Panadería La Ceiba", "Cayey", "Pueblo", .central, 18.1150, -66.1630, owned: true),
        // No owner yet: "¿Es tu negocio?" (try it with `-vantage 18.1400,-66.2660`). 555 numbers are fictional.
        point(ID.farmaciaDelPueblo, .business, "Farmacia del Pueblo", "Aibonito", "Pueblo", .central, 18.1400, -66.2660, phone: "(787) 555-0142"),
        point(ID.colmadoDonaCarmen, .business, "Colmado Doña Carmen", "Mayagüez", "Miradero", .west, 18.2200, -67.1380, owned: true),
    ]

    nonisolated static let roads: [Place] = [
        road(ID.pr52Caguas, "PR-52, km 14", "Caguas", .central, [(18.2780, -66.0560), (18.2700, -66.0500), (18.2620, -66.0450)]),
        road(ID.pr156Comerio, "PR-156, km 31", "Comerío", .central, [(18.2230, -66.2400), (18.2192, -66.2256), (18.2150, -66.2100)]),
        road(ID.pr2Mayaguez, "PR-2, km 156", "Mayagüez", .west, [(18.2300, -67.1500), (18.2200, -67.1450), (18.2100, -67.1420)]),
        road(ID.pr115Rincon, "PR-115, km 12", "Rincón", .west, [(18.3500, -67.2400), (18.3402, -67.2499), (18.3300, -67.2450)]),
    ]

    nonisolated static let areas: [Place] = [
        area(ID.bairoa, "Bairoa", "Caguas", .central, bairoaRing),
        area(ID.rioPiedras, "Río Piedras", "San Juan", .metro, rioPiedrasRing),
        area(ID.miradero, "Miradero", "Mayagüez", .west, miraderoRing),
        area(ID.comerioPueblo, "Comerío Pueblo", "Comerío", .central, comerioRing),
        // Where the sample stands, with nothing reported yet: Quick Report's area reports land here.
        area(ID.puebloViejo, "Pueblo Viejo", "Guaynabo", .metro, puebloViejoRing),
        area(ID.frailes, "Frailes", "Guaynabo", .metro, frailesRing),
    ]

    nonisolated static let puebloViejoRing = ring([(18.4120, -66.1180), (18.4120, -66.0980), (18.3920, -66.0980), (18.3920, -66.1180)])
    nonisolated static let frailesRing = ring([(18.3850, -66.1300), (18.3850, -66.1100), (18.3650, -66.1100), (18.3650, -66.1300)])

    nonisolated static let bairoaRing = ring([(18.2650, -66.0480), (18.2650, -66.0280), (18.2480, -66.0280), (18.2480, -66.0480)])
    nonisolated static let rioPiedrasRing = ring([(18.4080, -66.0600), (18.4080, -66.0420), (18.3900, -66.0420), (18.3900, -66.0600)])
    nonisolated static let miraderoRing = ring([(18.2280, -67.1500), (18.2280, -67.1330), (18.2120, -67.1330), (18.2120, -67.1500)])
    nonisolated static let comerioRing = ring([(18.2240, -66.2320), (18.2240, -66.2180), (18.2120, -66.2180), (18.2120, -66.2320)])

    // MARK: - Builders

    private static func station(
        _ id: String, _ name: String, brand: String?, _ municipio: String, _ barrio: String,
        _ region: Region, _ latitude: Double, _ longitude: Double
    ) -> Place {
        Place(
            id: id, kind: .station, name: name, municipio: municipio, barrio: barrio,
            region: region, geometry: .point(GeoPoint(latitude, longitude)), brand: brand
        )
    }

    private static func point(
        _ id: String, _ kind: Place.Kind, _ name: String, _ municipio: String, _ barrio: String,
        _ region: Region, _ latitude: Double, _ longitude: Double, owned: Bool = false, ports: [ChargerPort] = [], phone: String? = nil
    ) -> Place {
        Place(
            id: id, kind: kind, name: name, municipio: municipio, barrio: barrio,
            region: region, geometry: .point(GeoPoint(latitude, longitude)), hasVerifiedOwner: owned, ports: ports, publicPhone: phone
        )
    }

    private static func road(
        _ id: String, _ name: String, _ municipio: String, _ region: Region, _ points: [(Double, Double)]
    ) -> Place {
        Place(id: id, kind: .roadSegment, name: name, municipio: municipio, region: region, geometry: .line(ring(points)))
    }

    private static func area(
        _ id: String, _ barrio: String, _ municipio: String, _ region: Region, _ ring: [GeoPoint]
    ) -> Place {
        Place(id: id, kind: .area, name: barrio, municipio: municipio, barrio: barrio, region: region, geometry: .polygon(ring))
    }

    private static func ring(_ points: [(Double, Double)]) -> [GeoPoint] {
        points.map { GeoPoint($0.0, $0.1) }
    }
}
