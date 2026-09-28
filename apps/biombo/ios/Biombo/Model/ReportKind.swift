import Foundation

/// Every report type, per layer (PRODUCT.md §6). These are also the Siri
/// report types, so the vocabulary is fixed here from phase 1 (§15).
nonisolated enum ReportKind: String, CaseIterable, Codable, Hashable, Sendable {
    // Gas prices (§6.1)
    case price
    case stationClosed
    // Fuel and generator availability, the Disponibilidad mode of gas (§6.5)
    case hasGas
    case noGas
    case hasDiesel
    case noDiesel
    case queue
    case cashOnly
    case perPersonLimit
    case openOnGenerator
    case hasIce
    case hasCookingGas

    // Power (§6.2)
    case noPower
    case powerBack
    case unstablePower
    case lineDown
    case transformerBlew

    // Water (§6.3)
    case noWater
    case waterBack
    case lowPressure
    case cloudyWater
    case sawBoilNotice
    case waterPoint
    case brokenPipe

    // Signal (§6.4)
    case noSignal
    case callsOnly
    case hasData
    case signalSpot

    // Roads (§6.6)
    case flooded
    case landslide
    case closed
    case oneLane
    case highClearanceOnly
    case treeOrPole
    case pothole
    case reopened

    // EV chargers (§6.7)
    case chargerWorks
    case chargerBroken
    case slowCharging
    case connectorDamaged
    case chargerBusy
    case chargerBlocked
    case needsAppOrCard
    case newCharger

    // Businesses (§6.8); owners post the first three too, plus the owner-only kinds.
    case businessOpen
    case businessClosed
    case businessOnGenerator
    case productAvailable
    case event
    case specialHours

    var layer: Layer {
        switch self {
        case .price, .stationClosed, .hasGas, .noGas, .hasDiesel, .noDiesel, .queue,
             .cashOnly, .perPersonLimit, .openOnGenerator, .hasIce, .hasCookingGas:
            .gas
        case .noPower, .powerBack, .unstablePower, .lineDown, .transformerBlew:
            .power
        case .noWater, .waterBack, .lowPressure, .cloudyWater, .sawBoilNotice, .waterPoint, .brokenPipe:
            .water
        case .noSignal, .callsOnly, .hasData, .signalSpot:
            .signal
        case .flooded, .landslide, .closed, .oneLane, .highClearanceOnly, .treeOrPole, .pothole, .reopened:
            .roads
        case .chargerWorks, .chargerBroken, .slowCharging, .connectorDamaged, .chargerBusy,
             .chargerBlocked, .needsAppOrCard, .newCharger:
            .chargers
        case .businessOpen, .businessClosed, .businessOnGenerator, .productAvailable, .event, .specialHours:
            .businesses
        }
    }

    /// Kinds only a verified owner can post about their own place (§6.8).
    var isOwnerOnly: Bool {
        switch self {
        case .productAvailable, .event, .specialHours: true
        default: false
        }
    }

    static func kinds(for layer: Layer) -> [ReportKind] {
        allCases.filter { $0.layer == layer }
    }
}
