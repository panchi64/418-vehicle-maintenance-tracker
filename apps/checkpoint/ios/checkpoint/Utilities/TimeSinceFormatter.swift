//
//  TimeSinceFormatter.swift
//  checkpoint
//
//  Shared time-since formatting for contextual insights
//

import Foundation

enum TimeSinceFormatter {
    /// Full, sentence-cased: "5 months ago", "32 days ago", "Yesterday",
    /// "Today". Used where the value stands alone — a detail-view data row —
    /// so it keeps sentence-initial capitalization.
    static func full(from date: Date, relativeTo now: Date = .now) -> String {
        let (months, days) = elapsed(from: date, to: now)

        if months >= 1 {
            return months == 1 ? L10n.timeSinceOneMonthAgo : L10n.timeSinceMonthsAgo(months)
        } else if days <= 0 {
            return L10n.timeSinceTodaySentence
        } else if days == 1 {
            return L10n.timeSinceYesterdaySentence
        } else {
            return L10n.timeSinceDaysAgo(days)
        }
    }

    private static func elapsed(from date: Date, to now: Date) -> (months: Int, days: Int) {
        let components = Calendar.current.dateComponents([.month, .day], from: date, to: now)
        return (components.month ?? 0, components.day ?? 0)
    }
}
