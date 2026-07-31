//
//  ServiceTiming.swift
//  checkpoint
//
//  Replaces `ServiceMode`.
//
//  THE MODE SWITCH ASKED THE USER TO CLASSIFY THEIR OWN INTENT before the app
//  would let them describe it. "Record" and "Remind" are the app's words for its
//  own two save paths; a person changing their oil thinks "I did this on
//  Saturday" or "this is due in the spring". They should never have to translate.
//
//  So the form asks WHEN, and the intent falls out of the answer. A past answer
//  is a log; a future answer is a reminder. Neither word appears on screen — the
//  sheet title and the save button state what will happen, which is how the
//  derived intent stays visible without being a question.
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
    case inThreeMonths
    case inSixMonths
    case atMileage
    case onDate

    static let pastCases: [ServiceTiming] = [.today, .yesterday, .earlier]
    static let futureCases: [ServiceTiming] = [.inThreeMonths, .inSixMonths, .atMileage, .onDate]

    var intent: ServiceIntent {
        switch self {
        case .today, .yesterday, .earlier: return .log
        case .inThreeMonths, .inSixMonths, .atMileage, .onDate: return .schedule
        }
    }

    /// A log dated far enough back that it describes history rather than the
    /// present. Two things hang off this: the odometer must not be adopted, and
    /// a preset's default interval must not silently spawn a reminder.
    var isBackfill: Bool { self == .earlier }

    /// Whether the user still has to supply a date before this timing means
    /// anything.
    var needsExplicitDate: Bool { self == .earlier || self == .onDate }

    /// Whether the reminder fires on an odometer target rather than a date.
    var isMileageTriggered: Bool { self == .atMileage }

    var displayName: String {
        switch self {
        case .today: return L10n.timingToday
        case .yesterday: return L10n.timingYesterday
        case .earlier: return L10n.timingEarlier
        case .inThreeMonths: return L10n.timingInThreeMonths
        case .inSixMonths: return L10n.timingInSixMonths
        case .atMileage: return L10n.timingAtMileage
        case .onDate: return L10n.timingOnDate
        }
    }

    /// Resolves to the date the service was performed. Only meaningful for
    /// `.log` timings; `explicit` supplies the value for `.earlier`.
    func performedDate(explicit: Date, now: Date = .now) -> Date {
        switch self {
        case .today: return now
        case .yesterday:
            return Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        case .earlier: return explicit
        default: return now
        }
    }

    /// Resolves to the date the reminder is due, or nil when this timing fires
    /// on mileage instead. Only meaningful for `.schedule` timings.
    func dueDate(explicit: Date, now: Date = .now) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .inThreeMonths: return calendar.date(byAdding: .month, value: 3, to: now)
        case .inSixMonths: return calendar.date(byAdding: .month, value: 6, to: now)
        case .onDate: return explicit
        case .atMileage: return nil
        default: return nil
        }
    }
}
