import Foundation

/// "Tu aporte" (PRODUCT.md §10). Visible only to its owner; never affects
/// trust, which is a separate, hidden reputation (§5).
nonisolated struct Progress: Hashable, Sendable {
    var points: Int = 0
    /// The highest level ever reached: levels never go down.
    var levelFloor: Level = .one
    /// "Tu reporte ayudó a N personas", summed across reports. Feedback only.
    var peopleHelped: Int = 0
    var sentReports: Int = 0
    var confirmedReports: Int = 0
    /// The first report's capture time ("desde marzo").
    var since: Date?

    /// Five levels that never go down. Names live in the String Catalog.
    nonisolated enum Level: Int, CaseIterable, Codable, Hashable, Sendable, Comparable {
        case one = 1, two, three, four, five

        /// Point thresholds 0 / 10 / 40 / 120 / 300 (*proposed*).
        var threshold: Int {
            switch self {
            case .one: 0
            case .two: 10
            case .three: 40
            case .four: 120
            case .five: 300
            }
        }

        var next: Level? { Level(rawValue: rawValue + 1) }

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

        /// The level `points` reach on their own.
        static func reached(by points: Int) -> Level {
            allCases.last { points >= $0.threshold } ?? .one
        }
    }

    var level: Level { max(levelFloor, Level.reached(by: points)) }

    /// Points left to the next level, or nil at the top.
    var pointsToNextLevel: Int? {
        level.next.map { max(0, $0.threshold - points) }
    }

    /// How far into the current level, 0–1, for the wash filling its sketch.
    var levelFraction: Double {
        guard let next = level.next else { return 1 }
        let span = Double(next.threshold - level.threshold)
        return min(1, max(0, Double(points - level.threshold) / span))
    }
}

/// Points come only from outcomes, never from sending (§10, all *proposed*):
/// +3 for a report others confirmed (a confirmed reversal too), +1 for a vote
/// that matched the final resolution, +1 for the first confirmed report of
/// the day (never for a hazard), −2 for a report resolved against or
/// removed. A day earns at most 15; late reports earn nothing. The level
/// floor holds when points fall.
nonisolated struct ProgressLedger: Sendable {
    nonisolated static let confirmedReport = 3
    nonisolated static let agreeingVote = 1
    nonisolated static let firstOfTheDay = 1
    nonisolated static let resolvedAgainst = -2
    nonisolated static let dailyCap = 15

    var calendar = PuertoRico.calendar

    func progress(reports: [MyReport], votes: [MyVote]) -> Progress {
        var byDay: [Date: (gains: Int, losses: Int, hasFirst: Bool)] = [:]
        for mine in reports.sorted(by: { $0.report.capturedAt < $1.report.capturedAt }) {
            let day = calendar.startOfDay(for: mine.report.capturedAt)
            var entry = byDay[day] ?? (0, 0, false)
            switch mine.outcome {
            case .confirmed:
                entry.gains += Self.confirmedReport
                if !entry.hasFirst && !mine.report.kind.isHazard {
                    entry.gains += Self.firstOfTheDay
                    entry.hasFirst = true
                }
            case .resolvedAgainst, .removed:
                entry.losses += Self.resolvedAgainst
            case .waiting, .late:
                break
            }
            byDay[day] = entry
        }
        for vote in votes where vote.matchedResolution == true {
            let day = calendar.startOfDay(for: vote.castAt)
            var entry = byDay[day] ?? (0, 0, false)
            entry.gains += Self.agreeingVote
            byDay[day] = entry
        }

        var progress = Progress()
        for day in byDay.keys.sorted() {
            let entry = byDay[day]!
            progress.points = max(0, progress.points + min(entry.gains, Self.dailyCap) + entry.losses)
            progress.levelFloor = max(progress.levelFloor, Progress.Level.reached(by: progress.points))
        }
        progress.peopleHelped = reports.map(\.helped).reduce(0, +)
        progress.sentReports = reports.count
        progress.confirmedReports = reports.filter(\.outcome.isConfirmed).count
        progress.since = reports.map(\.report.capturedAt).min()
        return progress
    }
}
