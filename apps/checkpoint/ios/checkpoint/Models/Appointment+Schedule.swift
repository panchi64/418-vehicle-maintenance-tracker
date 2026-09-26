//
//  Appointment+Schedule.swift
//  checkpoint
//
//  Time rules for appointments, shared by Home, the form, the reminders and
//  Siri so they agree on what "upcoming", "conflict" and "when it ends" mean.
//

import Foundation

extension Appointment {

    /// How long a visit with no end time is assumed to take.
    nonisolated static let defaultDuration: TimeInterval = 60 * 60

    /// The end, or an hour after the start when the shop gave none.
    var effectiveEndDate: Date {
        guard let endDate, endDate > startDate else {
            return startDate.addingTimeInterval(Self.defaultDuration)
        }
        return endDate
    }

    var isScheduled: Bool { status == .scheduled }

    /// Shop name, trimmed; nil when blank.
    var trimmedShopName: String? {
        let trimmed = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Whether a place Maps can route to is on file (not just a shop name).
    var hasLocation: Bool {
        (latitude != nil && longitude != nil)
            || !(address?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    /// The linked services, by name, in a stable order.
    var sortedServices: [Service] {
        (services ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The scheduled appointments among `appointments`, soonest first. A
    /// visit whose time has passed stays until it is logged or cancelled —
    /// it is the prompt to log it.
    static func scheduled(_ appointments: [Appointment]) -> [Appointment] {
        appointments
            .filter(\.isScheduled)
            .sorted { $0.startDate < $1.startDate }
    }

    /// Other scheduled appointments of `vehicles` on the same calendar day as
    /// `date`, excluding `excluding` (the one being edited).
    static func sameDay(
        as date: Date,
        in appointments: [Appointment],
        excluding: UUID? = nil,
        calendar: Calendar = .current
    ) -> [Appointment] {
        scheduled(appointments).filter {
            $0.id != excluding && calendar.isDate($0.startDate, inSameDayAs: date)
        }
    }

    /// Where the relative tag on Home stands.
    enum Timing: Equatable {
        /// Later than today.
        case inDays(Int)
        /// Later today.
        case today
        /// Its start time has passed, and it hasn't been logged.
        case started(hoursAgo: Int)
    }

    func timing(now: Date = .now, calendar: Calendar = .current) -> Timing {
        if startDate <= now {
            return .started(hoursAgo: max(0, Int(now.timeIntervalSince(startDate) / 3600)))
        }
        if calendar.isDate(startDate, inSameDayAs: now) { return .today }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: startDate)
        ).day ?? 0
        return .inDays(max(1, days))
    }

    /// When a scheduled appointment reminds: the day before and an hour
    /// before, dropping any that have already passed.
    static func reminderDates(for start: Date, now: Date = .now) -> [ReminderLead: Date] {
        var dates: [ReminderLead: Date] = [:]
        for lead in ReminderLead.allCases {
            let date = start.addingTimeInterval(-lead.interval)
            if date > now { dates[lead] = date }
        }
        return dates
    }

    /// How far ahead of the start a reminder fires.
    nonisolated enum ReminderLead: String, CaseIterable, Sendable {
        case dayBefore = "1d"
        case hourBefore = "1h"

        var interval: TimeInterval {
            switch self {
            case .dayBefore: 24 * 60 * 60
            case .hourBefore: 60 * 60
            }
        }
    }
}
