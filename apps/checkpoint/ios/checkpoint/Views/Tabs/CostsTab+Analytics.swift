//
//  CostsTab+Analytics.swift
//  checkpoint
//
//  The Costs tab's numbers, derived in one pass. The value types they're
//  made of (`ExpenseEvent`, `CostMonth`, …) live in `CostsTab+Values.swift`.
//

import Foundation

// MARK: - Costs Metrics

/// Every number the Costs tab displays, computed once from the vehicle's logs
/// and the active period.
///
/// A SwiftUI body reads a property every time it mentions it, and building the
/// event list walks `log.visit` for every log, faulting SwiftData
/// relationships. So:
/// - **Stored, not computed**, if it iterates the events.
/// - Computed is fine for arithmetic or formatting over already-stored values
///   (`CostsTab+Insights.swift`).
struct CostsMetrics {
    let period: CostsTab.PeriodFilter

    /// Whether the vehicle has *any* costed expense, in any period. False puts
    /// the tab in its empty state instead of a screen of zeros.
    let hasAnyExpense: Bool
    /// Whether the vehicle has any service history at all, costed or not.
    let hasAnyLog: Bool

    /// Period-scoped events that carry a cost, newest first.
    let events: [ExpenseEvent]
    let totalSpent: Decimal

    /// The hero's secondary figure. For 30D this is the last-12-months
    /// average — thirty days is too short to average over — and
    /// `averageIsTwelveMonth` says so. nil when there is nothing to average.
    let monthlyAverage: Decimal?
    var averageIsTwelveMonth: Bool { period == .last30Days }

    /// One bar per calendar month in the period, oldest first, zero months
    /// kept (a gap is information). Capped at 24 bars.
    let trend: [CostMonth]
    let trendIsReady: Bool

    /// Largest first. Uncategorized is its own bucket.
    let bucketShares: [CostBucketShare]
    var categoryIsReady: Bool { bucketShares.count >= 2 }

    /// nil when last year has nothing to compare against by this date.
    let comparison: CostYearComparison?

    /// Newest month first.
    let monthGroups: [CostMonthGroup]

    let anomalyEventIDs: Set<UUID>

    /// The year the comparison is about, even when `comparison` is nil — the
    /// section title stays put while its content waits for data.
    let currentYear: Int

    // MARK: - Derivation

    /// - Parameter logs: the vehicle's logs, newest first. Already scoped to the
    ///   vehicle by the caller's query, so this does not re-filter them.
    init(
        logs: [ServiceLog],
        period: CostsTab.PeriodFilter,
        calendar: Calendar = .current,
        now: Date = .now
    ) {
        self.period = period
        self.hasAnyLog = !logs.isEmpty

        let allCosted = Self.expenseEvents(from: logs).filter(\.hasCost)
        self.hasAnyExpense = !allCosted.isEmpty

        let periodStart = period.startDate(now: now, calendar: calendar)
        let events = allCosted.filter { event in
            event.date <= now && periodStart.map { event.date >= $0 } ?? true
        }
        self.events = events
        let totalSpent = events.reduce(Decimal(0)) { $0 + $1.amount }
        self.totalSpent = totalSpent

        // MARK: Averages and the month span

        let thisMonth = Self.monthStart(of: now, calendar: calendar)
        // Months from the later of the period start and the first expense: a
        // July-only history averaged over seven YTD months read "$10 a month".
        let spanStart: Date? = {
            guard let oldest = events.last?.date else { return nil }
            guard let periodStart else { return oldest }
            return max(oldest, periodStart)
        }()
        let monthsSpanned = spanStart.map {
            Self.monthsInclusive(from: $0, to: now, calendar: calendar)
        } ?? 1

        if period == .last30Days {
            let yearAgo = CostsTab.PeriodFilter.last12Months.startDate(now: now, calendar: calendar) ?? now
            let lastYear = allCosted.filter { $0.date >= yearAgo && $0.date <= now }
            self.monthlyAverage = lastYear.isEmpty
                ? nil
                : lastYear.reduce(Decimal(0)) { $0 + $1.amount } / 12
        } else {
            self.monthlyAverage = events.isEmpty ? nil : totalSpent / Decimal(monthsSpanned)
        }

        // MARK: Trend

        var byMonth: [Date: Decimal] = [:]
        for event in events {
            byMonth[Self.monthStart(of: event.date, calendar: calendar), default: 0] += event.amount
        }
        let barCount = period == .last30Days ? 2 : min(monthsSpanned, 24)
        let trend: [CostMonth] = (0..<barCount).compactMap { index in
            guard let month = calendar.date(byAdding: .month, value: index - (barCount - 1), to: thisMonth)
            else { return nil }
            return CostMonth(month: month, amount: byMonth[month] ?? 0)
        }
        self.trend = trend
        self.trendIsReady = period == .last30Days
            ? events.count >= 2
            : trend.filter { $0.amount > 0 }.count >= 3

        // MARK: Buckets

        var byBucket: [CostBucket: Decimal] = [:]
        for event in events {
            byBucket[event.bucket, default: 0] += event.amount
        }
        let totalDouble = NSDecimalNumber(decimal: totalSpent).doubleValue
        self.bucketShares = byBucket
            .map { bucket, amount in
                CostBucketShare(
                    bucket: bucket,
                    amount: amount,
                    fraction: totalDouble > 0 ? NSDecimalNumber(decimal: amount).doubleValue / totalDouble : 0
                )
            }
            .sorted { $0.amount > $1.amount }

        // MARK: Year comparison

        let year = calendar.component(.year, from: now)
        self.currentYear = year
        self.comparison = Self.yearComparison(events: allCosted, year: year, now: now, calendar: calendar)

        // MARK: Month groups

        var groups: [CostMonthGroup] = []
        for event in events {  // newest first, so groups come out newest first
            let month = Self.monthStart(of: event.date, calendar: calendar)
            if let last = groups.last, last.month == month {
                groups[groups.count - 1] = CostMonthGroup(
                    month: month,
                    total: last.total + event.amount,
                    events: last.events + [event]
                )
            } else {
                groups.append(CostMonthGroup(month: month, total: event.amount, events: [event]))
            }
        }
        self.monthGroups = groups

        self.anomalyEventIDs = CostsInsightsCore.detectAnomalies(events: events)
    }

    // MARK: - Helpers

    /// Visits once, logs that belong to a visit absorbed into it, newest first.
    private static func expenseEvents(from logs: [ServiceLog]) -> [ExpenseEvent] {
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

    private static func monthStart(of date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    /// Calendar months touched from `start` through `end`, counting both ends.
    private static func monthsInclusive(from start: Date, to end: Date, calendar: Calendar) -> Int {
        let a = calendar.dateComponents([.year, .month], from: start)
        let b = calendar.dateComponents([.year, .month], from: end)
        let months = ((b.year ?? 0) - (a.year ?? 0)) * 12 + (b.month ?? 0) - (a.month ?? 0) + 1
        return max(1, months)
    }

    /// Jan 1 → now this year, against Jan 1 → the same date last year. nil
    /// when last year's span has no spend: there is nothing to be a percent of.
    private static func yearComparison(
        events: [ExpenseEvent],
        year: Int,
        now: Date,
        calendar: Calendar
    ) -> CostYearComparison? {
        guard let thisStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let lastStart = calendar.date(from: DateComponents(year: year - 1, month: 1, day: 1)),
              let lastEnd = calendar.date(byAdding: .year, value: -1, to: now)
        else { return nil }

        var thisYear: Decimal = 0
        var lastYear: Decimal = 0
        for event in events {
            if event.date >= thisStart && event.date <= now {
                thisYear += event.amount
            } else if event.date >= lastStart && event.date <= lastEnd {
                lastYear += event.amount
            }
        }
        guard lastYear > 0 else { return nil }

        let change = NSDecimalNumber(decimal: (thisYear - lastYear) / lastYear * 100).doubleValue
        return CostYearComparison(
            year: year,
            thisYearTotal: thisYear,
            lastYearTotal: lastYear,
            percentChange: Int(change.rounded())
        )
    }
}
