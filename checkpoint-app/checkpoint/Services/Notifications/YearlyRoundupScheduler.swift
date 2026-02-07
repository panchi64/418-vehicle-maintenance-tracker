//
//  YearlyRoundupScheduler.swift
//  checkpoint
//
//  Handles scheduling and canceling yearly cost roundup notifications
//

import Foundation
import UserNotifications
import os

private let yearlyNotificationLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "Notifications.Yearly")

/// Scheduler for yearly cost roundup notifications
struct YearlyRoundupScheduler {

    // MARK: - UserDefaults Keys

    private static let lastYearlyRoundupYearKey = "lastYearlyRoundupYear"

    // MARK: - Notification IDs

    /// Notification ID for yearly roundup (per vehicle per year)
    static func yearlyRoundupID(for vehicleID: UUID, year: Int) -> String {
        "yearly-roundup-\(vehicleID.uuidString)-\(year)"
    }

    // MARK: - Tracking

    /// Check if yearly roundup was already sent for a specific year
    static func hasShownYearlyRoundup(for year: Int, vehicleID: UUID) -> Bool {
        let key = "\(lastYearlyRoundupYearKey)-\(vehicleID.uuidString)"
        return UserDefaults.standard.integer(forKey: key) >= year
    }

    /// Mark yearly roundup as shown for a specific year
    static func markYearlyRoundupShown(for year: Int, vehicleID: UUID) {
        let key = "\(lastYearlyRoundupYearKey)-\(vehicleID.uuidString)"
        UserDefaults.standard.set(year, forKey: key)
    }

    // MARK: - Build Notification Requests

    /// Build a yearly cost roundup notification request
    static func buildYearlyRoundupRequest(
        vehicleName: String,
        vehicleID: UUID,
        year: Int,
        totalCost: Decimal,
        notificationDate: Date
    ) -> UNNotificationRequest {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        let formattedCost = formatter.string(from: totalCost as NSDecimalNumber) ?? "$0"

        let content = UNMutableNotificationContent()
        content.title = "\(year) Expense Report"
        content.body = "\(vehicleName) cost you \(formattedCost) last year. You're welcome."
        content.sound = .default
        content.categoryIdentifier = NotificationService.yearlyRoundupCategoryID
        content.userInfo = [
            "vehicleID": vehicleID.uuidString,
            "year": year,
            "type": "yearlyRoundup"
        ]

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = 10  // 10 AM for yearly roundup
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(
            identifier: yearlyRoundupID(for: vehicleID, year: year),
            content: content,
            trigger: trigger
        )
    }

    // MARK: - Schedule Notifications

    /// Schedule yearly cost roundup notification for January 2nd
    /// - Parameters:
    ///   - vehicle: The vehicle to show roundup for
    ///   - previousYearCost: Total cost for the previous year (if > 0)
    ///   - previousYear: The year being summarized
    static func scheduleYearlyRoundup(for vehicle: Vehicle, previousYearCost: Decimal, previousYear: Int) {
        // Only send if there's actual cost data
        guard previousYearCost > 0 else { return }

        // Don't send if already sent for this year
        guard !hasShownYearlyRoundup(for: previousYear, vehicleID: vehicle.id) else { return }

        // Calculate January 2nd of the following year
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = previousYear + 1
        dateComponents.month = 1
        dateComponents.day = 2

        guard let notificationDate = calendar.date(from: dateComponents) else { return }

        // Only schedule if date is in the future
        guard notificationDate > Date() else {
            // If we're past Jan 2nd, don't schedule but consider sending immediately
            // via a different mechanism if needed
            return
        }

        let request = buildYearlyRoundupRequest(
            vehicleName: vehicle.displayName,
            vehicleID: vehicle.id,
            year: previousYear,
            totalCost: previousYearCost,
            notificationDate: notificationDate
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                yearlyNotificationLogger.error("Failed to schedule yearly roundup: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cancel Notifications

    /// Cancel yearly roundup notification for a vehicle
    static func cancelYearlyRoundup(for vehicle: Vehicle, year: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [yearlyRoundupID(for: vehicle.id, year: year)]
        )
    }
}
