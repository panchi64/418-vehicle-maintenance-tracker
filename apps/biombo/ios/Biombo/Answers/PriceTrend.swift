import Foundation

/// A station's price over the last 30 days (PRODUCT.md §6.1): community
/// reports only, one point per day (that day's answer), gaps never
/// interpolated. It shows only once there is enough to say something.
nonisolated struct PriceTrend: Hashable, Sendable {
    struct Point: Hashable, Sendable {
        /// Midnight in Puerto Rico.
        let day: Date
        let centsPerLitre: Double
    }

    let grade: FuelGrade
    /// Oldest first; days with no reports are missing, not filled in.
    let points: [Point]
    /// Days from the first point to today, at most `windowDays`: what "en N días" says.
    let days: Int

    nonisolated static let windowDays = 30
    /// Shown once there are this many report-days spanning this many days (*proposed*).
    nonisolated static let minimumDays = 3
    nonisolated static let minimumSpanDays = 7

    init?(reports: [Report], placeID: Place.ID, grade: FuelGrade, now: Date, calendar: Calendar = PuertoRico.calendar) {
        let today = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -Self.windowDays, to: today) else { return nil }
        let priced = reports.compactMap { report -> (Date, Double)? in
            guard report.placeID == placeID, report.source == .community,
                  let price = report.price, price.grade == grade,
                  report.capturedAt >= start, report.capturedAt <= now else { return nil }
            return (report.capturedAt, price.centsPerLitre)
        }
        let byDay = Dictionary(grouping: priced) { calendar.startOfDay(for: $0.0) }
        let points = byDay
            .map { day, reports in Point(day: day, centsPerLitre: Self.dayAnswer(reports)) }
            .sorted { $0.day < $1.day }
        guard points.count >= Self.minimumDays,
              let first = points.first, let last = points.last,
              let span = calendar.dateComponents([.day], from: first.day, to: last.day).day,
              span >= Self.minimumSpanDays else { return nil }
        self.grade = grade
        self.points = points
        self.days = min(calendar.dateComponents([.day], from: first.day, to: today).day ?? span, Self.windowDays)
    }

    /// That day's answer: the median once there are enough, else the latest (§6.1).
    private static func dayAnswer(_ reports: [(Date, Double)]) -> Double {
        if reports.count >= AnswerResolver.medianMinimum, let median = reports.map(\.1).median {
            return median
        }
        return reports.max { $0.0 < $1.0 }!.1
    }

    /// Last point minus first, in ¢/L.
    var change: Double {
        (points.last?.centsPerLitre ?? 0) - (points.first?.centsPerLitre ?? 0)
    }

    var first: FuelPrice { FuelPrice(grade: grade, centsPerLitre: points.first?.centsPerLitre ?? 0) }
    var last: FuelPrice { FuelPrice(grade: grade, centsPerLitre: points.last?.centsPerLitre ?? 0) }
}

nonisolated extension [Double] {
    /// The middle value, or the mean of the middle two; nil when empty.
    var median: Double? {
        guard !isEmpty else { return nil }
        let sorted = sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
