import Foundation

/// A future time as people say an estimate: the day and a part of it
/// ("mañana en la tarde"), never a clock time, since an estimate is not
/// that precise (PRODUCT.md §3 "Numbers for glancing", V2-Outage).
nonisolated struct DayWindow: Hashable, Sendable {
    nonisolated enum Day: Hashable, Sendable {
        case today
        case tomorrow
        /// Any later day, said by its weekday.
        case later(Date)
    }

    nonisolated enum Part: Hashable, Sendable {
        case morning
        case afternoon
        case night
    }

    let day: Day
    let part: Part

    /// The small hours belong to the night before: 2 a. m. Wednesday is
    /// "el martes en la noche", as people say it.
    init(_ date: Date, now: Date, calendar: Calendar = PuertoRico.calendar) {
        let hour = calendar.component(.hour, from: date)
        let dayOf = hour < 5 ? date.addingTimeInterval(-.hours(5)) : date
        switch hour {
        case 5..<12: part = .morning
        case 12..<18: part = .afternoon
        default: part = .night
        }
        if calendar.isDate(dayOf, inSameDayAs: now) {
            day = .today
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(dayOf, inSameDayAs: tomorrow) {
            day = .tomorrow
        } else {
            day = .later(dayOf)
        }
    }
}
