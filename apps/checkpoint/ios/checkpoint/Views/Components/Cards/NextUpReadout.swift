//
//  NextUpReadout.swift
//  checkpoint
//
//  What the Next Up hero says, decided apart from how it is drawn.
//
//  THE HERO SHOWS WHICHEVER TRIGGER IS CLOSER. A service is due by miles OR by
//  date, whichever comes first. The card used to lead with miles whenever a
//  mileage trigger existed, so an oil change whose *date* had lapsed read
//  "2,100 MI REMAINING" — true, and the less urgent of the two facts. Miles are
//  converted to days at the vehicle's pace (the same conversion
//  `Service.urgencyScore` sorts by) and the nearer trigger becomes the hero.
//
//  The marbete has no odometer relationship, so its hero is always days.
//

import Foundation

struct NextUpReadout: Equatable {
    enum Figure: Equatable {
        /// Distance in miles (display converts to the user's unit). Negative = past.
        case distance(Int)
        /// Whole days. Negative = past.
        case days(Int)
    }

    enum Kind: Equatable {
        case service
        case marbete
    }

    let kind: Kind
    /// Nil only for an item with no trigger at all, which Next Up never picks.
    let figure: Figure?

    var isPast: Bool {
        switch figure {
        case .distance(let miles): return miles < 0
        case .days(let days): return days < 0
        case nil: return false
        }
    }

    /// Default pace when a vehicle has no history, matching `urgencyScore`.
    static let fallbackDailyPace = 40.0

    static func service(
        _ service: Service,
        currentMileage: Int,
        dailyPace: Double?,
        now: Date = .now
    ) -> NextUpReadout {
        let miles = service.dueMileage.map { $0 - currentMileage }
        let days = service.dueDate.map { dayCount(from: now, to: $0) }

        let figure: Figure?
        switch (miles, days) {
        case (nil, nil):
            figure = nil
        case (let miles?, nil):
            figure = .distance(miles)
        case (nil, let days?):
            figure = .days(days)
        case (let miles?, let days?):
            let pace = dailyPace.flatMap { $0 > 0 ? $0 : nil } ?? fallbackDailyPace
            let milesAsDays = Double(miles) / pace
            figure = milesAsDays < Double(days) ? .distance(miles) : .days(days)
        }
        return NextUpReadout(kind: .service, figure: figure)
    }

    static func marbete(daysUntilExpiration: Int?) -> NextUpReadout {
        NextUpReadout(kind: .marbete, figure: daysUntilExpiration.map { .days($0) })
    }

    /// Calendar days between the two dates' starts, so "due tomorrow" is 1 at
    /// any hour today.
    private static func dayCount(from now: Date, to date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
    }
}
