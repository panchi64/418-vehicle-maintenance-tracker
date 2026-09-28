import AppIntents

/// What can be reported by voice (PRODUCT.md §11 App Shortcuts: no power,
/// power back, no water, a road, fuel). The words read inside "Reporta en
/// Biombo que …", so they are lower case. Raw values are saved by
/// shortcuts: never rename one.
nonisolated enum ReportCondition: String, CaseIterable, AppEnum {
    case noPower
    case powerBack
    case noWater
    case waterBack
    case noSignal
    case flooded
    case landslide
    case roadClosed
    case noGas
    case hasGas

    var kind: ReportKind {
        switch self {
        case .noPower: .noPower
        case .powerBack: .powerBack
        case .noWater: .noWater
        case .waterBack: .waterBack
        case .noSignal: .noSignal
        case .flooded: .flooded
        case .landslide: .landslide
        case .roadClosed: .closed
        case .noGas: .noGas
        case .hasGas: .hasGas
        }
    }

    // App Intents metadata is read at build time, so these stay plain literals.
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Qué pasa" }

    static var caseDisplayRepresentations: [ReportCondition: DisplayRepresentation] {
        [
            .noPower: DisplayRepresentation(title: "no hay luz", image: .init(systemName: "bolt.slash.fill")),
            .powerBack: DisplayRepresentation(title: "volvió la luz", image: .init(systemName: "bolt.fill")),
            .noWater: DisplayRepresentation(title: "no hay agua", image: .init(systemName: "drop")),
            .waterBack: DisplayRepresentation(title: "volvió el agua", image: .init(systemName: "drop.fill")),
            .noSignal: DisplayRepresentation(title: "no hay señal", image: .init(systemName: "antenna.radiowaves.left.and.right.slash")),
            .flooded: DisplayRepresentation(title: "la carretera está inundada", image: .init(systemName: "water.waves")),
            .landslide: DisplayRepresentation(title: "hay un derrumbe", image: .init(systemName: "exclamationmark.triangle.fill")),
            .roadClosed: DisplayRepresentation(title: "la carretera está cerrada", image: .init(systemName: "road.lanes")),
            .noGas: DisplayRepresentation(title: "no hay gasolina", image: .init(systemName: "fuelpump.slash.fill")),
            .hasGas: DisplayRepresentation(title: "hay gasolina", image: .init(systemName: "fuelpump.fill"))
        ]
    }
}

/// The services "¿Hay luz?" asks about: the ones that go out in areas (§7).
nonisolated enum CheckedService: String, CaseIterable, AppEnum {
    case power
    case water
    case signal

    var layer: Layer {
        switch self {
        case .power: .power
        case .water: .water
        case .signal: .signal
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Servicio" }

    static var caseDisplayRepresentations: [CheckedService: DisplayRepresentation] {
        [
            .power: DisplayRepresentation(title: "luz", image: .init(systemName: "bolt.fill")),
            .water: DisplayRepresentation(title: "agua", image: .init(systemName: "drop.fill")),
            .signal: DisplayRepresentation(title: "señal", image: .init(systemName: "antenna.radiowaves.left.and.right"))
        ]
    }
}
