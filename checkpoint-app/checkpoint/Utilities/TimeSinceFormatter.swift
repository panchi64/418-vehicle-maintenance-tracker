//
//  TimeSinceFormatter.swift
//  checkpoint
//
//  Shared time-since formatting for contextual insights
//

import Foundation

enum TimeSinceFormatter {
    /// Full format: "5 months ago", "32 days ago", "Yesterday", "Today"
    static func full(from date: Date, relativeTo now: Date = .now) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date, to: now)
        let months = components.month ?? 0
        let days = components.day ?? 0

        if months >= 1 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else if days <= 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else {
            return "\(days) days ago"
        }
    }

    /// Abbreviated format: "5 MO AGO", "12D AGO", "YESTERDAY", "TODAY"
    static func abbreviated(from date: Date, relativeTo now: Date = .now) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date, to: now)
        let months = components.month ?? 0
        let days = components.day ?? 0

        if months >= 1 {
            return "\(months) MO AGO"
        } else if days <= 0 {
            return "TODAY"
        } else if days == 1 {
            return "YESTERDAY"
        } else {
            return "\(days)D AGO"
        }
    }
}
