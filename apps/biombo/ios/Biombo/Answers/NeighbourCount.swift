import Foundation

/// A coarse age ("hoy en la tarde"). Community reports on a business show
/// only this, never exact times, so an owner can't tell which customer
/// reported (PRODUCT.md §6.8).
nonisolated enum CoarseAge: Hashable, Sendable {
    case thisMorning
    case thisAfternoon
    case tonight
    case yesterday
    case earlier

    init(_ date: Date, now: Date, calendar: Calendar = PuertoRico.calendar) {
        if calendar.isDate(date, inSameDayAs: now) {
            switch calendar.component(.hour, from: date) {
            case ..<12: self = .thisMorning
            case ..<18: self = .thisAfternoon
            default: self = .tonight
            }
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            self = .yesterday
        } else {
            self = .earlier
        }
    }
}

/// "Lo que dicen los vecinos" on a place a verified owner holds: community
/// reports as counts per kind. They can dispute the owner, never hide them.
nonisolated struct NeighbourCount: Hashable, Sendable {
    let kind: ReportKind
    let count: Int
    let age: CoarseAge

    /// The community reports among `evidence` (the resolver's current reports
    /// on one place and layer), grouped by kind, most reported first.
    static func counts(_ evidence: [PlaceAnswer], now: Date) -> [NeighbourCount] {
        let community = evidence.filter { $0.lead.source == .community }
        return Dictionary(grouping: community, by: \.kind)
            .compactMap { kind, group in
                group.map(\.asOf).max().map { NeighbourCount(kind: kind, count: group.count, age: CoarseAge($0, now: now)) }
            }
            .sorted { ($0.count, $0.kind.rawValue) > ($1.count, $1.kind.rawValue) }
    }
}
