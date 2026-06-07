//
//  DuePeriodFormatter.swift
//  checkpoint
//
//  Turns a due/expiration date into an abstracted, top-of-mind period label
//  ("Mid May", "Early Aug 2027") instead of a raw day count, which isn't very
//  actionable. Near-term and past dates collapse to "This week" / "Overdue".
//

import Foundation

nonisolated enum DuePeriodFormatter {
    /// Items due within this many days read as "This week" rather than a
    /// month bucket — "mid May" on May 13th isn't useful.
    private static let thisWeekThreshold = 7

    /// Stable English month abbreviations (indexed by calendar month, 1–12) so
    /// the brutalist labels read uniformly regardless of device locale (the rest
    /// of the card is fixed English). A plain array sidesteps the non-Sendable
    /// `DateFormatter`, keeping this whole formatter `nonisolated`.
    private static let monthAbbreviations = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]

    /// Abstracted due descriptor in natural case (callers uppercase for display).
    /// Examples: "Overdue", "This week", "Early May", "Mid Aug 2027".
    static func describe(_ date: Date, relativeTo now: Date = .now, calendar: Calendar = .current) -> String {
        let startNow = calendar.startOfDay(for: now)
        let startDue = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startNow, to: startDue).day ?? 0

        if days < 0 { return "Overdue" }
        if days <= thisWeekThreshold { return "This week" }

        let dayOfMonth = calendar.component(.day, from: startDue)
        let bucket: String
        switch dayOfMonth {
        case ...10: bucket = "Early"
        case 11...20: bucket = "Mid"
        default: bucket = "Late"
        }

        let month = monthAbbreviations[calendar.component(.month, from: date) - 1]
        let dueYear = calendar.component(.year, from: date)
        let nowYear = calendar.component(.year, from: now)
        let yearSuffix = dueYear == nowYear ? "" : " \(dueYear)"

        return "\(bucket) \(month)\(yearSuffix)"
    }
}
