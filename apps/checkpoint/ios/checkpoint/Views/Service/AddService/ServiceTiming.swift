//
//  ServiceTiming.swift
//  checkpoint
//
//  THE FORM ASKS WHEN, AND THE INTENT FALLS OUT OF THE ANSWER. A past answer
//  is a log; "Not done yet" is a reminder. Neither word appears on screen — the
//  sheet title states what will happen, which is how the derived intent stays
//  visible without being a question.
//
//  Today is the default. The past/future chip grid this replaced had no
//  default, so every entry cost a tap just to say "today" — and seven chips in
//  two groups asked the user to pick a scheduling horizon before the form had
//  shown them the service's own interval. Now "Not done yet" is one chip, and
//  *when it is due* is asked afterwards (`ServiceDueKind`), defaulting to the
//  service's interval.
//

import Foundation

/// What the form will do on save. Derived from `ServiceTiming`, never chosen.
enum ServiceIntent: Equatable {
    case log
    case schedule
}

enum ServiceTiming: String, CaseIterable, Hashable, Codable {
    // Already done
    case today
    case yesterday
    case earlier

    // Coming up
    case notYet

    static let pastCases: [ServiceTiming] = [.today, .yesterday, .earlier]

    var intent: ServiceIntent {
        self == .notYet ? .schedule : .log
    }

    /// A log dated by hand describes history rather than the present. Two
    /// things hang off this: the odometer must not be adopted, and a preset's
    /// default interval must not silently spawn a reminder.
    var isBackfill: Bool { self == .earlier }

    /// Whether the user still has to supply the performed date.
    var needsExplicitDate: Bool { self == .earlier }

    var displayName: String {
        switch self {
        case .today: return L10n.timingToday
        case .yesterday: return L10n.timingYesterday
        case .earlier: return L10n.timingOnDate
        case .notYet: return L10n.timingNotYet
        }
    }

    /// Resolves to the date the service was performed; `explicit` supplies the
    /// value for `.earlier`. Meaningless for `.notYet`, which returns `now`.
    func performedDate(explicit: Date, now: Date = .now) -> Date {
        switch self {
        case .today, .notYet: return now
        case .yesterday:
            return Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        case .earlier: return explicit
        }
    }
}

/// When a "Not done yet" reminder fires.
enum ServiceDueKind: String, CaseIterable, Hashable, Codable {
    /// The service's own cadence, counted from today and the current odometer.
    /// The default whenever the service has one, so scheduling is saveable
    /// without typing anything.
    case interval
    case date
    case mileage
}
