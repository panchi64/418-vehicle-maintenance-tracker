//
//  ServiceLog+Analytics.swift
//  checkpoint
//
//  Visit-aware cost helpers. The fundamental rule:
//    - A standalone log (visit == nil) contributes its own `cost`.
//    - An itemized-visit log contributes its own `cost` (per-service portion).
//    - An un-itemized-visit log contributes nothing per-log; the visit's
//      `totalCost` contributes once for the whole visit.
//
//  Use `attributableCost` for "what should I show on this row" and
//  `[ServiceLog].honestTotalCost()` for "what's the honest sum across these logs".
//

import Foundation

extension ServiceLog {
    /// Cost attributable to this individual log row.
    /// Returns nil for un-itemized visit logs (consult `visit?.totalCost` instead).
    var attributableCost: Decimal? {
        if let visit, !visit.isItemized { return nil }
        return cost
    }

    var isPartOfVisit: Bool { visit != nil }
}

extension Sequence where Element == ServiceLog {
    /// Sum costs honestly across a collection of logs:
    ///   - per-log cost when attributable (standalone or itemized-visit log)
    ///   - visit `totalCost` counted once per un-itemized visit
    func honestTotalCost() -> Decimal {
        var total: Decimal = 0
        var countedVisits: Set<UUID> = []
        for log in self {
            if let visit = log.visit, !visit.isItemized {
                if !countedVisits.contains(visit.id) {
                    countedVisits.insert(visit.id)
                    total += visit.totalCost ?? 0
                }
            } else if let cost = log.cost {
                total += cost
            }
        }
        return total
    }

    /// Number of distinct "money events" represented by this log set:
    ///   - one per un-itemized visit (regardless of how many logs share it)
    ///   - one per itemized log (or standalone log) that has a cost
    func distinctVisitCount() -> Int {
        var visitIDs: Set<UUID> = []
        var standaloneCount = 0
        for log in self {
            if let visit = log.visit {
                visitIDs.insert(visit.id)
            } else if log.cost != nil {
                standaloneCount += 1
            }
        }
        return visitIDs.count + standaloneCount
    }
}
