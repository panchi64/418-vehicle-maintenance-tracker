//
//  CostsTab+Values.swift
//  checkpoint
//
//  The value types the Costs tab's numbers are made of.
//
//  All money metrics flow from `ExpenseEvent`s, not raw `ServiceLog`s.
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

    var amount: Decimal {
        switch self {
        case .standalone(let log): return log.cost ?? 0
        case .visit(let visit): return visit.totalCost ?? 0
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

/// One bucket's share of the period total.
struct CostBucketShare: Identifiable, Equatable {
    let bucket: CostBucket
    let amount: Decimal
    /// 0...1 of the period total.
    let fraction: Double
    var id: CostBucket { bucket }
}

// MARK: - Months

/// One calendar month's spend. `month` is the first instant of the month.
struct CostMonth: Identifiable, Equatable {
    let month: Date
    let amount: Decimal
    var id: Date { month }
}

/// The expense list's unit: a calendar month, its total, its events newest first.
struct CostMonthGroup: Identifiable {
    let month: Date
    let total: Decimal
    let events: [ExpenseEvent]
    var id: Date { month }
}

// MARK: - Comparison

/// This calendar year so far against the same span of last year.
struct CostYearComparison: Equatable {
    let year: Int
    let thisYearTotal: Decimal
    let lastYearTotal: Decimal
    /// Rounded; positive = more than last year.
    let percentChange: Int
}
