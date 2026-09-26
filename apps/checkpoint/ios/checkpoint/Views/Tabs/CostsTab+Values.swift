//
//  CostsTab+Values.swift
//  checkpoint
//
//  The value types the Costs tab's numbers are made of.
//
//  All money metrics flow from `ExpenseEvent`s (Models/ExpenseEvent.swift),
//  not raw `ServiceLog`s, via `CostAnalyticsService` — so a Service Visit
//  counts once, here and in the App Intents that answer spending questions.
//

import Foundation

// MARK: - Buckets

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
