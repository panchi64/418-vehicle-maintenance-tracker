//
//  NotificationHelpers.swift
//  checkpoint
//
//  Shared helpers for building notification triggers
//

import Foundation
import UserNotifications

enum NotificationHelpers {
    /// Default notification hour (9 AM)
    static let defaultHour = 9
    static let defaultMinute = 0

    /// Build a calendar trigger for a given date at the default notification time
    static func calendarTrigger(for date: Date, hour: Int = defaultHour, minute: Int = defaultMinute) -> UNCalendarNotificationTrigger {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
}
