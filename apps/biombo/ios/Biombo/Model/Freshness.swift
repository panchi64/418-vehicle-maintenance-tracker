import Foundation

/// Where an item sits on its decay clock (PRODUCT.md §4.4).
///
/// Only `.fresh` and `.aging` items feed the answer, the map, Siri and widgets.
/// `.stale` items live behind "Ver reportes anteriores (N)" with their age first;
/// `.expired` items are gone from the app and kept only for history.
nonisolated enum Freshness: String, Codable, Hashable, Sendable {
    case fresh
    /// Past half its window: still counts, with the trust suffix promoted.
    case aging
    case stale
    case expired

    /// Counts toward the answer, the map, Siri and widgets.
    var isCurrent: Bool { self == .fresh || self == .aging }

    /// Listed behind "Ver reportes anteriores", never drawn or spoken.
    var isRevealableOnly: Bool { self == .stale }
}

/// The freshness gate. Pure: every call takes `now`, so tests and sample data are deterministic.
nonisolated struct FreshnessPolicy: Sendable {
    /// How long past its window an item stays revealable before it leaves the app.
    /// *Proposed*; §4.4 only says the horizon is longer than the window.
    var showOlderHorizon: TimeInterval = .days(7)
    /// An open outage area stays drawn until reversal or this ceiling (§4.4).
    var outageCeiling: TimeInterval = .hours(72)
    var crisisOutageCeiling: TimeInterval = .days(7)
    /// An official feed turns aging when it is this late (LUMA's timestamp > 60 min).
    var feedLateAfter: TimeInterval = .minutes(60)
    /// A hand-entered official item with no update for this long turns aging.
    var handEntryAgingAfter: TimeInterval = .hours(72)

    /// The generic decay rule: fresh, then aging past 50%, then stale past the window.
    func evaluate(anchor: Date, window: TimeInterval, now: Date) -> Freshness {
        let age = max(0, now.timeIntervalSince(anchor))
        if age >= window + showOlderHorizon { return .expired }
        if age >= window { return .stale }
        if age >= window / 2 { return .aging }
        return .fresh
    }

    /// A single report. Official reports don't decay by age (see `evaluateOfficial`).
    func evaluate(_ report: Report, now: Date) -> Freshness {
        switch report.source {
        case .official:
            return evaluateOfficial(updatedAt: report.freshnessAnchor, isFeed: true, now: now)
        case .owner:
            if let end = report.statedEnd {
                return evaluate(anchor: report.freshnessAnchor, window: end.timeIntervalSince(report.freshnessAnchor), now: now)
            }
            return evaluate(anchor: report.freshnessAnchor, window: ReportKind.ownerDefaultWindow, now: now)
        case .community:
            return evaluate(anchor: report.freshnessAnchor, window: report.kind.decayWindow, now: now)
        }
    }

    /// Official items are current while the source says so; they only turn
    /// aging when the source itself is late. They never go stale by age alone.
    func evaluateOfficial(updatedAt: Date, isFeed: Bool, now: Date) -> Freshness {
        let lateAfter = isFeed ? feedLateAfter : handEntryAgingAfter
        return now.timeIntervalSince(updatedAt) >= lateAfter ? .aging : .fresh
    }

    /// Outage areas are states, not events (§4.4). A Confirmado or Oficial area
    /// stays current until it closes or hits the ceiling; its evidence only
    /// decides when it turns aging. Anything else decays like its reports.
    func evaluate(_ area: OutageArea, label: VerificationLabel, isCrisis: Bool, now: Date) -> Freshness {
        let window = outageWindow(for: area.layer)
        if area.lifecycle == .closed {
            return evaluate(anchor: area.latestEvidenceAt, window: 0, now: now)
        }
        guard label.holdsOutageOpen else {
            return evaluate(anchor: area.latestEvidenceAt, window: window, now: now)
        }
        let ceiling = isCrisis ? crisisOutageCeiling : outageCeiling
        if now.timeIntervalSince(area.openedAt) >= ceiling {
            // Reaching the ceiling is not a restoration: the area only moves
            // behind "Ver reportes anteriores", and nothing says "volvió".
            return evaluate(anchor: area.openedAt.addingTimeInterval(ceiling), window: 0, now: now)
        }
        // The starred window only sets when the evidence turns aging ("Último reporte hace 9 h").
        return now.timeIntervalSince(area.latestEvidenceAt) >= window ? .aging : .fresh
    }

    /// When a report stops being current (turns stale), so a widget can drop
    /// it on time. nil for official reports, which never go stale by age.
    func currentUntil(_ report: Report) -> Date? {
        switch report.source {
        case .official:
            return nil
        case .owner:
            return report.statedEnd ?? report.freshnessAnchor.addingTimeInterval(ReportKind.ownerDefaultWindow)
        case .community:
            return report.freshnessAnchor.addingTimeInterval(report.kind.decayWindow)
        }
    }

    /// The starred §4.4 windows that set when an open area's evidence turns aging.
    private func outageWindow(for layer: Layer) -> TimeInterval {
        switch layer {
        case .power: ReportKind.noPower.decayWindow
        case .water: ReportKind.noWater.decayWindow
        case .signal: ReportKind.noSignal.decayWindow
        case .roads, .gas, .chargers, .businesses: .hours(4)
        }
    }
}
