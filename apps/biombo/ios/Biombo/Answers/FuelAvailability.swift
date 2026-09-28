import Foundation

/// The Gasolina / Diésel switch of "Gasolina y planta" (PRODUCT.md §6.5).
nonisolated enum FuelKind: String, CaseIterable, Hashable, Sendable {
    case gasoline
    case diesel

    /// Statuses that say the station sells this fuel now.
    var positiveKinds: Set<ReportKind> {
        switch self {
        case .gasoline: [.hasGas, .queue, .cashOnly, .perPersonLimit, .openOnGenerator]
        case .diesel: [.hasDiesel]
        }
    }

    /// Statuses that say it doesn't.
    var negativeKinds: Set<ReportKind> {
        switch self {
        case .gasoline: [.noGas, .stationClosed]
        case .diesel: [.noDiesel, .stationClosed]
        }
    }

    /// A current pump price for one of these grades is also evidence of fuel.
    func sells(_ grade: FuelGrade) -> Bool {
        switch self {
        case .gasoline: grade != .diesel
        case .diesel: grade == .diesel
        }
    }

    /// How long "hay" counts: the §4.4 window of this fuel's "hay" report.
    var window: TimeInterval {
        self == .gasoline ? ReportKind.hasGas.decayWindow : ReportKind.hasDiesel.decayWindow
    }

    /// The availability kinds, without prices: what "Ver reportes anteriores" lists.
    var statusKinds: Set<ReportKind> { positiveKinds.union(negativeKinds).subtracting([.stationClosed]) }
}

/// One station's answer for one fuel: the report that states it, how far it
/// is, and what else neighbours said about the line.
nonisolated struct FuelStop: Identifiable, Hashable, Sendable {
    /// The report the answer stands on; a price counts as "hay".
    let answer: PlaceAnswer
    let distance: Double
    /// "Fila de unos 20 min", from a current queue report.
    let queueMinutes: Int?
    /// An owner "hay" contradicted by enough neighbours: the dispute is the news (§6.5).
    let isDisputed: Bool

    var id: Place.ID { answer.place.id }
    var place: Place { answer.place }
}

/// Where one fuel is and isn't nearby, nearest first.
nonisolated struct FuelAvailability: Hashable, Sendable {
    let fuel: FuelKind
    /// Stations with it, nearest first. The first one is the answer.
    let stops: [FuelStop]
    /// Stations without it: bad news, collapsed into one row (§6.5).
    let without: [FuelStop]
    /// Availability reports past their window, behind "Ver reportes anteriores".
    let older: [NearbyRow]
    /// How long an availability report counts, which the "why" line states.
    let window: TimeInterval

    var lead: FuelStop? { stops.first }

    /// The stations after the answer, capped (§3 row caps).
    func others(cap: Int) -> ArraySlice<FuelStop> { stops.dropFirst().prefix(cap) }
}

/// "Gasolina y planta": both fuels and the places open on a generator (§6.5).
nonisolated struct AvailabilityDigest: Hashable, Sendable {
    let gasoline: FuelAvailability
    let diesel: FuelAvailability
    /// "Abiertos con planta": open on a generator, or with ice or cooking gas, nearest first.
    let generators: [NearbyRow]

    func fuel(_ kind: FuelKind) -> FuelAvailability {
        kind == .gasoline ? gasoline : diesel
    }
}
