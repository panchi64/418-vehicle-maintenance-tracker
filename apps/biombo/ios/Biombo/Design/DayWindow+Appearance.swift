import Foundation

extension DayWindow {
    /// "mañana en la tarde", "el martes en la noche". Today's parts are the
    /// same words as a coarse age ("hoy en la tarde", "esta noche").
    func text(locale: Locale) -> LocalizedStringResource {
        switch (day, part) {
        case (.today, .morning): CoarseAge.thisMorning.text
        case (.today, .afternoon): CoarseAge.thisAfternoon.text
        case (.today, .night): CoarseAge.tonight.text
        case (.tomorrow, .morning): LocalizedStringResource("mañana en la mañana", comment: "Estimate window: tomorrow morning")
        case (.tomorrow, .afternoon): LocalizedStringResource("mañana en la tarde", comment: "Estimate window: tomorrow afternoon")
        case (.tomorrow, .night): LocalizedStringResource("mañana en la noche", comment: "Estimate window: tomorrow night")
        case (.later(let date), let part):
            Self.later(date.island(.dateTime.weekday(.wide), locale: locale), part: part)
        }
    }

    private static func later(_ weekday: String, part: Part) -> LocalizedStringResource {
        switch part {
        case .morning: LocalizedStringResource("el \(weekday) en la mañana", comment: "Estimate window: a later weekday's morning, e.g. 'el martes en la mañana'")
        case .afternoon: LocalizedStringResource("el \(weekday) en la tarde", comment: "Estimate window: a later weekday's afternoon")
        case .night: LocalizedStringResource("el \(weekday) en la noche", comment: "Estimate window: a later weekday's night")
        }
    }
}
