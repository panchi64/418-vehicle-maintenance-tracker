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
        if sharedCostVisit != nil { return nil }
        return cost
    }

    var isPartOfVisit: Bool { visit != nil }

    /// The un-itemized visit whose `totalCost` stands in for this log's cost,
    /// or nil when the log carries its own cost (standalone or itemized).
    var sharedCostVisit: ServiceVisit? {
        guard let visit, !visit.isItemized else { return nil }
        return visit
    }

    /// The cost an edit form should show for this log: the shared visit total
    /// when there is one, else the log's own cost. Falls back to the log's own
    /// cost for a visit without a total, so a cost stranded on a child log by
    /// an older build still surfaces for correction.
    var editableCost: Decimal? {
        guard let visit = sharedCostVisit else { return cost }
        return visit.totalCost ?? cost
    }

    var editableCostCategory: CostCategory? {
        guard let visit = sharedCostVisit else { return costCategory }
        return visit.totalCost != nil ? visit.costCategory : costCategory
    }

    /// Writes an edited cost where the cost analytics read it. An un-itemized
    /// visit's total is the only money the Costs tab counts for its logs, so a
    /// cost written to one of those child logs would silently vanish from it.
    func applyEditedCost(_ newCost: Decimal?, category: CostCategory) {
        let newCategory = newCost != nil ? category : nil
        if let visit = sharedCostVisit {
            visit.totalCost = newCost
            visit.costCategory = newCategory
            cost = nil
            costCategory = nil
        } else {
            cost = newCost
            costCategory = newCategory
        }
    }
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
