//
//  Vehicle+MarbeteRenewal.swift
//  checkpoint
//
//  Renewing the marbete from Home's Next Up card.
//
//  The marbete renews annually in the same month, so "renewed" has one
//  answer: the next expiration after today, same month. That makes renewal a
//  confirmation rather than a form — the old path opened Edit Vehicle and made
//  the user find and re-pick the year.
//

import Foundation

extension Vehicle {
    /// Month and year of a marbete expiration.
    struct MarbeteExpiration: Equatable {
        let month: Int
        let year: Int
    }

    var marbeteExpiration: MarbeteExpiration? {
        guard let month = marbeteExpirationMonth, let year = marbeteExpirationYear else { return nil }
        return MarbeteExpiration(month: month, year: year)
    }

    /// The expiration a renewal moves to: one year past the current one, and
    /// past `now` even if the sticker lapsed more than a year ago. Nil when no
    /// marbete is configured.
    func renewedMarbeteExpiration(now: Date = .now) -> MarbeteExpiration? {
        guard let current = marbeteExpiration else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        var year = current.year + 1
        while let lastDay = Self.lastDay(month: current.month, year: year, calendar: calendar),
              lastDay < today {
            year += 1
        }
        return MarbeteExpiration(month: current.month, year: year)
    }

    func applyMarbeteExpiration(_ expiration: MarbeteExpiration) {
        marbeteExpirationMonth = expiration.month
        marbeteExpirationYear = expiration.year
    }

    /// Localized "September 2027".
    static func marbeteExpirationLabel(_ expiration: MarbeteExpiration) -> String {
        guard let date = Calendar.current.date(from: DateComponents(year: expiration.year, month: expiration.month, day: 1)) else {
            return "\(expiration.month)/\(expiration.year)"
        }
        return date.formatted(.dateTime.month(.wide).year())
    }

    private static func lastDay(month: Int, year: Int, calendar: Calendar) -> Date? {
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: first)
    }
}
