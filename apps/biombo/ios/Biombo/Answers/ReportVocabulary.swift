import Foundation

/// What Quick Report offers (PRODUCT.md §4.2, direction §3.6): three
/// contextual one-tap verbs, and under "Otra cosa…" each layer's ≤4 verbs
/// plus a Más menu for the rest. Inside a reported problem the reversal
/// comes first; in crisis gas speaks availability, not prices (§8).
/// Owner-only kinds never appear here.
nonisolated enum ReportVocabulary {
    /// The first screen's verbs for `layer`, given the answer already standing there.
    static func oneTap(for layer: Layer, current: ReportKind?, isCrisis: Bool) -> [ReportKind] {
        switch layer {
        case .power:
            current == .noPower ? [.powerBack, .noPower, .lineDown] : [.noPower, .unstablePower, .lineDown]
        case .water:
            current == .noWater ? [.waterBack, .noWater, .cloudyWater] : [.noWater, .lowPressure, .cloudyWater]
        case .signal:
            current == .noSignal ? [.hasData, .noSignal, .callsOnly] : [.noSignal, .callsOnly, .signalSpot]
        case .roads:
            if let current, current.reversedBy == .reopened {
                Array(([.reopened, current] + roadProblems).uniqued().prefix(3))
            } else {
                roadProblems
            }
        case .gas:
            if isCrisis || current == .noGas {
                [.hasGas, .noGas, .queue]
            } else {
                [.price, .queue, .noGas]
            }
        case .chargers:
            [.chargerWorks, .chargerBroken, .chargerBusy]
        case .businesses:
            isCrisis ? [.businessOnGenerator, .businessOpen, .businessClosed] : [.businessOpen, .businessClosed, .businessOnGenerator]
        }
    }

    private static let roadProblems: [ReportKind] = [.flooded, .landslide, .closed]

    /// Nothing in reach to snap to: the three reports anyone can make where they stand.
    static let whereYouStand: [ReportKind] = [.noPower, .noWater, .noSignal]

    /// A layer's page under "Otra cosa…": at most four verbs.
    static func primary(for layer: Layer, isCrisis: Bool) -> [ReportKind] {
        switch layer {
        case .power: [.noPower, .powerBack, .lineDown, .transformerBlew]
        case .water: [.noWater, .waterBack, .cloudyWater, .brokenPipe]
        case .signal: [.noSignal, .hasData, .callsOnly, .signalSpot]
        case .roads: [.flooded, .landslide, .closed, .reopened]
        case .gas: isCrisis ? [.hasGas, .noGas, .hasDiesel, .queue] : [.price, .hasGas, .noGas, .queue]
        case .chargers: [.chargerWorks, .chargerBroken, .chargerBusy, .slowCharging]
        case .businesses: [.businessOpen, .businessClosed, .businessOnGenerator]
        }
    }

    /// The rest of the layer's kinds, in the Más menu, so every report stays reachable.
    static func more(for layer: Layer, isCrisis: Bool) -> [ReportKind] {
        let shown = Set(primary(for: layer, isCrisis: isCrisis))
        return ReportKind.kinds(for: layer).filter { !shown.contains($0) && !$0.isOwnerOnly }
    }
}

extension ReportKind {
    /// The report that reverses this problem, if one does ("Abierta otra vez").
    nonisolated var reversedBy: ReportKind? {
        switch self {
        case .flooded, .landslide, .closed, .oneLane, .treeOrPole, .highClearanceOnly: .reopened
        default: ReportKind.allCases.first { $0.reverses == self }
        }
    }

    /// A price is the only report that needs typing (§4.2).
    nonisolated var needsTyping: Bool { self == .price }
}

private extension Array where Element: Hashable {
    nonisolated func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
