//
//  ServiceVisit+Reconciliation.swift
//  checkpoint
//
//  Itemize/total reconciliation rules. Used by Phase B's live capture UI;
//  ships dormant in Phase A so the API is in place when itemize lands.
//
//  Rules:
//    - sum < total → positive residual ("Shop charge" line in detail)
//    - sum > total → negative residual (block save)
//    - !isItemized OR totalCost == nil → no residual (return nil)
//

import Foundation

extension ServiceVisit {
    var itemizedSum: Decimal {
        let serviceSum = (logs ?? []).compactMap { $0.cost }.reduce(Decimal.zero, +)
        let lineSum = (lineItems ?? []).map { $0.amount }.reduce(Decimal.zero, +)
        return serviceSum + lineSum
    }

    /// nil when not itemized or no total entered.
    /// Positive → display as "Shop charge" residual.
    /// Negative → save should be blocked.
    var reconciliationResidual: Decimal? {
        guard isItemized, let total = totalCost else { return nil }
        return total - itemizedSum
    }

    var hasOverflow: Bool {
        guard let residual = reconciliationResidual else { return false }
        return residual < 0
    }

    /// "Shop charge" residual to display when itemized and the total covers
    /// more than the itemized sum. Returns nil when there's nothing to show.
    var shopChargeResidual: Decimal? {
        guard let residual = reconciliationResidual, residual > 0 else { return nil }
        return residual
    }
}
