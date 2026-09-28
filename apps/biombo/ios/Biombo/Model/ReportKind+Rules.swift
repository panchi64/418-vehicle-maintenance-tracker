import Foundation

/// Per-kind rules: decay windows (PRODUCT.md §4.4), confirmation thresholds
/// (§4.5), reversals (§4.2) and hazards (§6.6, §10). All numbers are *proposed*.
nonisolated extension ReportKind {
    /// How long a community report counts before it leaves the answer.
    ///
    /// Kinds the §4.4 table doesn't list take the nearest sibling's window;
    /// those are marked "unlisted".
    var decayWindow: TimeInterval {
        switch self {
        case .price, .stationClosed: .hours(48)
        case .hasGas, .noGas, .hasDiesel, .noDiesel: .hours(2)
        case .queue: .minutes(45)
        case .openOnGenerator: .hours(4)
        case .cashOnly: .hours(12)
        case .perPersonLimit: .hours(2) // unlisted: follows hay / no hay
        case .hasIce, .hasCookingGas: .hours(4) // unlisted: follows planta

        case .noPower: .hours(4)
        case .powerBack: .hours(2)
        case .unstablePower: .hours(4) // unlisted: follows no hay
        case .lineDown, .transformerBlew: .hours(12)

        case .noWater: .hours(8)
        case .waterBack: .hours(4)
        case .lowPressure, .cloudyWater: .hours(6)
        case .sawBoilNotice: .hours(12) // unlisted: a depth line only
        case .waterPoint: .hours(12)
        case .brokenPipe: .hours(12) // unlisted: follows point hazards

        case .noSignal, .callsOnly: .hours(2)
        case .hasData: .hours(1)
        case .signalSpot: .hours(24)

        case .flooded: .hours(3)
        case .landslide, .closed: .hours(24)
        case .oneLane, .treeOrPole, .highClearanceOnly, .pothole: .hours(12)
        case .reopened: .hours(6)

        case .chargerWorks, .chargerBroken, .slowCharging, .needsAppOrCard, .newCharger: .hours(6)
        case .chargerBusy, .chargerBlocked: .minutes(30)
        case .connectorDamaged: .hours(72)

        case .businessOpen, .businessClosed, .businessOnGenerator, .productAvailable, .specialHours: .hours(4)
        case .event: .hours(12)
        }
    }

    /// An owner post lasts until its stated end, or this long without one (§4.4).
    static let ownerDefaultWindow: TimeInterval = .hours(12)

    /// Outages are states, not events (§4.4 starred rows): once their area is
    /// Confirmado or Oficial it stays open past this window until reversed.
    var isOutageState: Bool {
        switch self {
        case .noPower, .noWater, .noSignal: true
        default: false
        }
    }

    /// High-harm negatives need more independent weight to reach Confirmado (§4.5).
    var isHighHarmNegative: Bool {
        switch self {
        case .noGas, .noDiesel, .businessClosed, .chargerBroken, .closed, .landslide: true
        default: false
        }
    }

    /// A station status that makes its pump price moot: closed, or out of gas.
    var meansNoFuel: Bool {
        self == .stationClosed || self == .noGas
    }

    /// Hazards show "Aléjate. Si hay peligro, llama al 911." when sent and earn
    /// only confirmation points (§6.2, §6.6, §10).
    var isHazard: Bool {
        switch self {
        case .lineDown, .transformerBlew, .flooded, .landslide, .treeOrPole, .pothole: true
        default: false
        }
    }

    /// The problem this kind reverses, if it is a reversal ("Volvió la luz").
    /// A reversal is both a new report and a "Ya no" vote on the opposite one (§4.2).
    var reverses: ReportKind? {
        switch self {
        case .powerBack: .noPower
        case .waterBack: .noWater
        case .hasData: .noSignal
        case .reopened: .closed
        case .hasGas: .noGas
        case .hasDiesel: .noDiesel
        case .chargerWorks: .chargerBroken
        case .businessOpen: .businessClosed
        default: nil
        }
    }
}

nonisolated extension TimeInterval {
    static func minutes(_ value: Double) -> TimeInterval { value * 60 }
    static func hours(_ value: Double) -> TimeInterval { value * 3600 }
    static func days(_ value: Double) -> TimeInterval { value * 86_400 }
}
