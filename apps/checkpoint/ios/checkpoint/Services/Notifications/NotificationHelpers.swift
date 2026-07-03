//
//  NotificationHelpers.swift
//  checkpoint
//
//  Shared helpers for building notification triggers
//

import Foundation
import UserNotifications
import os

private let notificationBudgetLogger = Logger(category: "Notifications.Budget")

enum NotificationHelpers {
    /// Default notification hour (9 AM)
    static let defaultHour = 9
    static let defaultMinute = 0

    /// How soon a same-day reminder fires when its snapped notification time
    /// has already passed (see `reminderTrigger`).
    static let fireSoonInterval: TimeInterval = 60

    /// iOS silently keeps only the 64 soonest-firing pending notification
    /// requests and drops the rest. Trim to headroom below that after any bulk
    /// reschedule so a nearer reminder is never dropped for a farther one.
    static let pendingRequestBudget = 60

    /// Build a calendar trigger for a given date at the default notification time
    static func calendarTrigger(for date: Date, hour: Int = defaultHour, minute: Int = defaultMinute) -> UNCalendarNotificationTrigger {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    /// The concrete moment a calendar trigger for `date` will fire, after
    /// snapping to the notification hour/minute. The raw `date` can be later in
    /// the day than the snapped time, so callers must gate on this — not on
    /// `date` — or a reminder scheduled after 9 AM produces a past,
    /// non-repeating trigger that iOS never delivers.
    static func snappedFireDate(for date: Date, hour: Int = defaultHour, minute: Int = defaultMinute) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    /// Trigger for a reminder targeted at `date`, or nil if it should be
    /// skipped. If the snapped notification time is still in the future, fires
    /// then; if it has already passed but `date` is still today, fires shortly
    /// so a same-day ("due today") reminder isn't silently dropped; otherwise
    /// the target is genuinely in the past and returns nil.
    static func reminderTrigger(
        for date: Date,
        hour: Int = defaultHour,
        minute: Int = defaultMinute,
        now: Date = Date()
    ) -> UNNotificationTrigger? {
        guard let fireDate = snappedFireDate(for: date, hour: hour, minute: minute) else { return nil }
        if fireDate > now {
            return calendarTrigger(for: date, hour: hour, minute: minute)
        }
        if Calendar.current.isDate(date, inSameDayAs: now) {
            return UNTimeIntervalNotificationTrigger(timeInterval: fireSoonInterval, repeats: false)
        }
        return nil
    }

    // MARK: - Pending Request Budget

    /// The concrete next fire date for a request, or nil if it can't be
    /// determined. Undeterminable requests sort last so date-driven ones win
    /// the budget.
    static func nextFireDate(for request: UNNotificationRequest) -> Date? {
        guard let trigger = request.trigger else { return nil }
        switch trigger {
        case let calendar as UNCalendarNotificationTrigger:
            return calendar.nextTriggerDate()
        case let interval as UNTimeIntervalNotificationTrigger:
            return interval.nextTriggerDate()
        default:
            return nil
        }
    }

    /// Pure selection: identifiers of the requests that fall outside the
    /// `budget` soonest-firing ones (the set to remove). Extracted from
    /// `enforcePendingBudget` so the keep-soonest/drop-furthest choice is
    /// testable without the notification center.
    static func identifiersOverBudget(in requests: [UNNotificationRequest], budget: Int) -> [String] {
        guard requests.count > budget else { return [] }
        let sorted = requests.sorted {
            (nextFireDate(for: $0) ?? .distantFuture) < (nextFireDate(for: $1) ?? .distantFuture)
        }
        return sorted.dropFirst(budget).map(\.identifier)
    }

    /// Trim pending requests to `budget`, keeping the soonest-firing ones so
    /// the OS's own 64-request cap can't silently drop a nearer reminder in
    /// favor of a farther one. Returns the number removed.
    @discardableResult
    static func enforcePendingBudget(_ budget: Int = pendingRequestBudget) async -> Int {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let overflowIDs = identifiersOverBudget(in: pending, budget: budget)
        guard !overflowIDs.isEmpty else { return 0 }
        center.removePendingNotificationRequests(withIdentifiers: overflowIDs)
        notificationBudgetLogger.info("Trimmed \(overflowIDs.count) pending notification(s) over budget \(budget); OS keeps only the 64 soonest")
        return overflowIDs.count
    }
}
