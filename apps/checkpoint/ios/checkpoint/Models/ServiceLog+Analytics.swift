//
//  ServiceLog+Analytics.swift
//  checkpoint
//
//  Visit-aware per-log cost helpers: what a single log's row shows and where
//  an edited cost is written.
//    - A standalone log (visit == nil) shows its own `cost`.
//    - An itemized-visit log shows its own `cost` (per-service portion).
//    - An un-itemized-visit log shows nothing per-log; its money lives in the
//      visit's `totalCost`.
//
//  Sums across logs are `CostAnalyticsService`'s — never add these up yourself.
//

import Foundation

extension ServiceLog {
    /// Cost attributable to this individual log row.
    /// Returns nil for un-itemized visit logs (consult `visit?.totalCost` instead).
    var attributableCost: Decimal? {
        if sharedCostVisit != nil { return nil }
        return cost
    }

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
