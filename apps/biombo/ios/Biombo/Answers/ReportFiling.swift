import Foundation

/// How a new report is filed (PRODUCT.md §4.2): a repeat of the same type on
/// the same place within 15 minutes is a confirmation of the standing report
/// (for prices, the same grade within ±1¢/L), not a new one. Pure.
nonisolated enum ReportFiling: Hashable, Sendable {
    case new(Report)
    /// Counted as "Sigue igual" on a neighbour's report.
    case confirmation(of: Report)
    /// You said the same thing a moment ago; nothing new is sent.
    case repeatOfYours(Report)

    static func file(_ report: Report, among reports: [Report], ownReports: Set<Report.ID>) -> ReportFiling {
        let match = reports
            .filter { $0.placeID == report.placeID && $0.kind == report.kind && $0.source == .community && $0.id != report.id }
            .filter { report.capturedAt.timeIntervalSince($0.freshnessAnchor) <= ContributionRules.repeatWindow }
            .filter { report.capturedAt >= $0.capturedAt }
            .filter { samePrice($0.price, report.price) }
            .max { $0.freshnessAnchor < $1.freshnessAnchor }
        guard let match else { return .new(report) }
        return ownReports.contains(match.id) ? .repeatOfYours(match) : .confirmation(of: match)
    }

    private static func samePrice(_ lhs: FuelPrice?, _ rhs: FuelPrice?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (lhs?, rhs?): lhs.grade == rhs.grade && abs(lhs.centsPerLitre - rhs.centsPerLitre) <= ContributionRules.priceRepeatTolerance
        default: false
        }
    }
}

/// The sent state (§4.2): one sentence plus Deshacer for 5 seconds. Luz and
/// agua say the utility isn't told (§6.2, §6.3); hazards add the 911 line
/// (§6.2, §6.6); offline says it goes out with signal (§4.6).
nonisolated struct ReportReceipt: Identifiable, Hashable, Sendable {
    nonisolated enum Delivery: Hashable, Sendable {
        /// On the map now, for neighbours to see.
        case sent
        /// Waiting in the outbox for signal.
        case queued
        /// It matched a neighbour's report, so it counted as a confirmation.
        case confirmed(neighbours: Int)
        /// You already said this a moment ago.
        case alreadySaid
        /// A price far outside DACO's range, held until someone confirms it (§6.1).
        case heldForReview
    }

    let reportID: Report.ID
    let kind: ReportKind
    let placeName: String
    let delivery: Delivery
    /// An outage no drawn area covers yet: one device isn't an area (§6.2
    /// edge cases, §7), so it says "Parece que es solo tu casa o tu calle".
    var isAloneForNow = false
    /// A price report's price, which the sent sentence states.
    var price: FuelPrice?
    /// For a confirmation: the vote it replaced, which Deshacer puts back
    /// (nil when there was none).
    var replacedVote: MyVote?

    var id: Report.ID { reportID }

    /// Users assume a report reaches the utility, so an outage or damage on
    /// luz and agua says it doesn't. "Volvió" needs nothing from it (§4.2).
    var handOff: Agency? {
        guard kind.reverses == nil else { return nil }
        return switch kind.layer {
        case .power: .luma
        case .water: .aaa
        default: nil
        }
    }

    /// "Aléjate. Si hay peligro, llama al 911."
    var showsSafetyLine: Bool { kind.isHazard }

    /// "Añadir detalle" offers the kind's optional value, where it has one
    /// and something was actually sent or queued.
    var detail: ReportDetailKind? {
        switch delivery {
        case .sent, .queued, .heldForReview: kind.detail
        case .confirmed, .alreadySaid: nil
        }
    }

    /// Deshacer takes back what this receipt stands for.
    var canUndo: Bool { delivery != .alreadySaid }

    /// A receipt with a hand-off or a safety line stays until closed.
    var staysUntilClosed: Bool { handOff != nil || showsSafetyLine }
}

/// The optional value "Añadir detalle" asks for (§4.2 fields).
nonisolated enum ReportDetailKind: Hashable, Sendable {
    case queueMinutes
    case carrier
    case connector

    /// "Fila de unos N min": the choices offered.
    nonisolated static let queueChoices = [10, 20, 30, 45, 60]
}

extension ReportKind {
    nonisolated var detail: ReportDetailKind? {
        switch self {
        case .queue: .queueMinutes
        case .noSignal, .callsOnly, .hasData, .signalSpot: .carrier
        case .chargerWorks, .chargerBroken, .slowCharging, .connectorDamaged: .connector
        default: nil
        }
    }
}
