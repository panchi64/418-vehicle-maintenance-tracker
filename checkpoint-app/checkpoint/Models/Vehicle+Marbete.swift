//
//  Vehicle+Marbete.swift
//  checkpoint
//
//  PR vehicle registration tag (marbete) tracking
//

import Foundation

extension Vehicle {
    /// Days threshold for "due soon" status (60 days for marbete)
    private static let marbeteDueSoonThreshold = 60

    /// Whether marbete expiration is configured (requires both month AND year)
    var hasMarbeteExpiration: Bool {
        marbeteExpirationMonth != nil && marbeteExpirationYear != nil
    }

    /// Whether marbete has a validation error (one field set but not the other)
    var hasMarbeteValidationError: Bool {
        (marbeteExpirationMonth != nil) != (marbeteExpirationYear != nil)
    }

    /// The last day of the marbete expiration month
    var marbeteExpirationDate: Date? {
        guard let month = marbeteExpirationMonth,
              let year = marbeteExpirationYear else { return nil }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstDay = Calendar.current.date(from: components) else { return nil }

        // Get the last day of the month
        guard let lastDay = Calendar.current.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: firstDay
        ) else { return nil }

        return lastDay
    }

    /// Days until marbete expiration (negative if expired)
    var daysUntilMarbeteExpiration: Int? {
        guard let expirationDate = marbeteExpirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: expirationDate)).day
    }

    /// Marbete status using 60-day "due soon" threshold
    var marbeteStatus: ServiceStatus {
        guard hasMarbeteExpiration else { return .neutral }
        guard let days = daysUntilMarbeteExpiration else { return .neutral }

        if days < 0 {
            return .overdue
        } else if days <= Self.marbeteDueSoonThreshold {
            return .dueSoon
        } else {
            return .good
        }
    }

    /// Formatted marbete expiration string (e.g., "March 2025")
    var marbeteExpirationFormatted: String? {
        guard let month = marbeteExpirationMonth,
              let year = marbeteExpirationYear else { return nil }

        let monthName = Calendar.current.monthSymbols[month - 1]
        return "\(monthName) \(year)"
    }

    /// Urgency score for marbete (for sorting with services)
    /// Lower score = more urgent
    var marbeteUrgencyScore: Int {
        guard hasMarbeteExpiration else { return Int.max }
        return daysUntilMarbeteExpiration ?? Int.max
    }
}
