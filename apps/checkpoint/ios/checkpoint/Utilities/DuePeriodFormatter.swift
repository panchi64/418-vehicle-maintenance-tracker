//
//  DuePeriodFormatter.swift
//  checkpoint
//
//  Turns a due/expiration date into an abstracted, top-of-mind period label
//  ("Mid May", "Early Aug 2027") instead of a raw day count, which isn't very
//  actionable. Near-term and past dates collapse to "This week" / "Overdue".
//
//  Localized: the month name and word order follow the device locale, and every
//  word ("Overdue", "Early/Mid/Late", "This week") is resolved through the app
//  catalog. Callers branch on `Period.isOverdue` rather than matching the label
//  string, so overdue detection survives translation (the Spanish label is
//  "Vencido", not "Overdue").
//

import Foundation

nonisolated enum DuePeriodFormatter {
    /// Items due within this many days read as "This week" rather than a
    /// month bucket — "mid May" on May 13th isn't useful.
    private static let thisWeekThreshold = 7

    /// A due date abstracted into a top-of-mind period.
    struct Period: Equatable {
        let isOverdue: Bool
        /// Localized, natural-case label: "Overdue" / "This week" / "Mid May".
        /// Callers uppercase (brutalist hero) or lowercase (phrase) for display.
        let label: String
    }

    /// Abstracted, localized due descriptor.
    static func describe(_ date: Date, relativeTo now: Date = .now, calendar: Calendar = .current) -> Period {
        let startNow = calendar.startOfDay(for: now)
        let startDue = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startNow, to: startDue).day ?? 0

        if days < 0 { return Period(isOverdue: true, label: String(localized: "Overdue")) }
        if days <= thisWeekThreshold { return Period(isOverdue: false, label: String(localized: "This week")) }

        // Locale-aware abbreviated month ("May" / "may"), carrying the year only
        // when it differs from now so near-term dates stay terse.
        let dueYear = calendar.component(.year, from: date)
        let nowYear = calendar.component(.year, from: now)
        let month = dueYear == nowYear
            ? date.formatted(.dateTime.month(.abbreviated))
            : date.formatted(.dateTime.month(.abbreviated).year())

        let dayOfMonth = calendar.component(.day, from: startDue)
        let label: String
        switch dayOfMonth {
        case ...10: label = String(localized: "Early \(month)")
        case 11...20: label = String(localized: "Mid \(month)")
        default: label = String(localized: "Late \(month)")
        }
        return Period(isOverdue: false, label: label)
    }
}
