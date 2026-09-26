//
//  ExpenseEvent.swift
//  checkpoint
//
//  The unit every cost figure is made of — on the Costs tab and in the App
//  Intents that answer spending questions (`CostAnalyticsService`).
//
//  An ExpenseEvent is one of:
//    - a standalone log with cost > 0
//    - a Service Visit with totalCost > 0
//
//  This means a Service Visit holding 4 services contributes ONCE to totals,
//  not 4 fabricated quarter-shares (the original bug). Logs that belong to a
//  visit but are not the visit itself are absorbed into the visit event.
//

import Foundation

// MARK: - Expense Event

/// Either a standalone service log with a cost or a Service Visit with a total.
/// Used as the unit of analysis for every cost-side metric.
enum ExpenseEvent: Identifiable {
    case standalone(ServiceLog)
    case visit(ServiceVisit)

    var id: UUID {
        switch self {
        case .standalone(let log): return log.id
        case .visit(let visit): return visit.id
        }
    }

    var date: Date {
        switch self {
        case .standalone(let log): return log.performedDate
        case .visit(let visit): return visit.performedDate
        }
    }

    /// Odometer reading at the time, in stored miles.
    var mileage: Int {
        switch self {
        case .standalone(let log): return log.mileageAtService
        case .visit(let visit): return visit.mileageAtVisit
        }
    }

    /// A visit's entered total is its whole cost — the itemized services and
    /// line items are a breakdown of it, never added on top. An itemized
    /// visit saved without a total falls back to that breakdown's sum, so its
    /// priced items still count (once) instead of vanishing.
    var amount: Decimal {
        switch self {
        case .standalone(let log): return log.cost ?? 0
        case .visit(let visit):
            if let total = visit.totalCost { return total }
            return visit.isItemized ? visit.itemizedSum : 0
        }
    }

    var category: CostCategory? {
        switch self {
        case .standalone(let log): return log.costCategory
        case .visit(let visit): return visit.costCategory
        }
    }

    /// The one rule for an expense with no category: it is its own bucket,
    /// everywhere. (The stacked chart used to count it as Maintenance while
    /// By Category left it out, so the two disagreed about the same dollars.)
    var bucket: CostBucket {
        category.map(CostBucket.category) ?? .uncategorized
    }

    var hasCost: Bool { amount > 0 }
}

// MARK: - Buckets

/// A cost category, or the absence of one.
enum CostBucket: Hashable {
    case category(CostCategory)
    case uncategorized

    var displayName: String {
        switch self {
        case .category(let category): return category.displayName
        case .uncategorized: return L10n.costsUncategorized
        }
    }
}
