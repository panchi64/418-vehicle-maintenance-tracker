//
//  CostAnalyticsService.swift
//  checkpoint
//
//  Spend figures shared by the Costs tab (`CostsMetrics`) and the App Intents
//  that answer "how much did I spend on the Civic this year?". One
//  implementation of the rules, so Siri can never quote a number the screen
//  disagrees with:
//
//    - a Service Visit counts once, however many services it holds
//      (`ExpenseEvent`);
//    - an expense with no category is its own bucket;
//    - a period never includes the future (`CostPeriod.contains`).
//
//  Stateless: every function takes the logs and a clock and returns values.
//

import Foundation

/// A period's spend, optionally narrowed to one category.
struct CostSummary: Equatable {
    let period: CostPeriod
    /// nil = every category.
    let category: CostCategory?
    let total: Decimal
    /// Distinct expenses (a visit is one) that carried a cost.
    let expenseCount: Int
    /// The period's spend per bucket, before any category narrowing.
    let totalsByBucket: [CostBucket: Decimal]
}

enum CostAnalyticsService {

    /// Every expense in `logs` — visits once, logs that belong to a visit
    /// absorbed into it — newest first. Includes uncosted events.
    static func expenseEvents(from logs: [ServiceLog]) -> [ExpenseEvent] {
        var seenVisitIDs: Set<UUID> = []
        var built: [ExpenseEvent] = []
        built.reserveCapacity(logs.count)
        for log in logs {
            if let visit = log.visit {
                guard seenVisitIDs.insert(visit.id).inserted else { continue }
                built.append(.visit(visit))
            } else {
                built.append(.standalone(log))
            }
        }
        // A visit's date can differ from the log that pulled it in, so arrival
        // order doesn't guarantee the events are sorted.
        return built.sorted { $0.date > $1.date }
    }

    /// The expenses in `logs` that carried a cost, newest first.
    static func costedEvents(from logs: [ServiceLog]) -> [ExpenseEvent] {
        expenseEvents(from: logs).filter(\.hasCost)
    }

    /// `events` that fall inside `period`, order preserved.
    static func events(
        _ events: [ExpenseEvent],
        in period: CostPeriod,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ExpenseEvent] {
        events.filter { period.contains($0.date, now: now, calendar: calendar) }
    }

    static func total(of events: [ExpenseEvent]) -> Decimal {
        events.reduce(Decimal(0)) { $0 + $1.amount }
    }

    static func totalsByBucket(_ events: [ExpenseEvent]) -> [CostBucket: Decimal] {
        var byBucket: [CostBucket: Decimal] = [:]
        for event in events {
            byBucket[event.bucket, default: 0] += event.amount
        }
        return byBucket
    }

    /// What was spent on `logs` during `period`, in `category` when one is
    /// given. `logs` should already be scoped to one vehicle.
    static func summary(
        logs: [ServiceLog],
        period: CostPeriod,
        category: CostCategory? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> CostSummary {
        let inPeriod = events(costedEvents(from: logs), in: period, now: now, calendar: calendar)
        let byBucket = totalsByBucket(inPeriod)
        let matching = category.map { wanted in inPeriod.filter { $0.category == wanted } } ?? inPeriod
        return CostSummary(
            period: period,
            category: category,
            total: total(of: matching),
            expenseCount: matching.count,
            totalsByBucket: byBucket
        )
    }
}
