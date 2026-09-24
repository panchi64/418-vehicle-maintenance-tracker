//
//  ServiceReminderBundle.swift
//  checkpoint
//
//  Groups a vehicle's service reminders so several services that come due
//  together arrive as one notification instead of one apiece.
//
//  Reminders used to be scheduled per service: four requests per service
//  (30/7/1/0 days before due), each with its own identifier. A vehicle with
//  five services due on the same date therefore delivered five banners at
//  9 AM — the same information, five times, with nothing to distinguish them.
//  Services coming due together is the common case, not the edge case: a
//  preset-driven schedule lines oil, filter, and rotation up on the same
//  mileage, and the app's own clustering feature exists precisely because
//  those get done in one shop visit.
//
//  Grouping is by fire day AND lead time, not by fire day alone. The lead time
//  is the message — "due today" and "due in 30 days" ask for different things,
//  and the notification's actions (Mark as Done, Remind Tomorrow) apply to the
//  whole set, so a set has to share an urgency for them to mean anything. Two
//  banners on a morning where one item is due and another is a month out is
//  the correct outcome; five banners for five items due today is not.
//
//  Exact-day grouping alone still split the services the app suggests doing
//  together — those only need to fall within the clustering window, and
//  mileage-projected due dates rarely land on the same day. So before
//  bundling, `ServiceClusteringService.reminderDueDates` moves each such group
//  onto its earliest member's due date; this file then sees them as one day.
//

import Foundation

/// One service asking for a reminder on a given day.
struct ServiceReminderOccurrence: Equatable {
    let serviceID: UUID
    let serviceName: String
    /// Lead time this reminder represents — one of `defaultReminderIntervals`.
    let daysBeforeDue: Int
    /// The day the reminder targets, before snapping to the notification hour.
    let notificationDate: Date
}

/// Every occurrence a vehicle has on one day at one lead time — the unit that
/// becomes a single `UNNotificationRequest`.
struct ServiceReminderBundle: Equatable {
    let daysBeforeDue: Int
    /// Representative target date for the group. All members fall on the same
    /// calendar day, and the trigger snaps to the notification hour, so any
    /// member's date produces the same trigger.
    let notificationDate: Date
    /// Sorted by service name, so the same data always yields the same content
    /// and a reschedule is a no-op rather than a reworded duplicate.
    let occurrences: [ServiceReminderOccurrence]

    var serviceIDs: [UUID] { occurrences.map(\.serviceID) }
    var serviceNames: [String] { occurrences.map(\.serviceName) }
    var count: Int { occurrences.count }

    /// Group occurrences into one bundle per (day, lead time).
    ///
    /// Ordered by fire date, then by descending lead time, so the output is
    /// stable across calls — identifiers and content are derived from it.
    static func bundles(
        from occurrences: [ServiceReminderOccurrence],
        calendar: Calendar = .current
    ) -> [ServiceReminderBundle] {
        struct Key: Hashable {
            let day: Date
            let daysBeforeDue: Int
        }

        let grouped = Dictionary(grouping: occurrences) { occurrence in
            Key(
                day: calendar.startOfDay(for: occurrence.notificationDate),
                daysBeforeDue: occurrence.daysBeforeDue
            )
        }

        return grouped
            .map { key, members in
                ServiceReminderBundle(
                    daysBeforeDue: key.daysBeforeDue,
                    // The earliest member: if any member is late enough in the
                    // day to need the fire-soon fallback, the group does too.
                    notificationDate: members.map(\.notificationDate).min() ?? key.day,
                    occurrences: members.sorted {
                        ($0.serviceName, $0.serviceID.uuidString)
                            < ($1.serviceName, $1.serviceID.uuidString)
                    }
                )
            }
            .sorted {
                if $0.notificationDate != $1.notificationDate {
                    return $0.notificationDate < $1.notificationDate
                }
                return $0.daysBeforeDue > $1.daysBeforeDue
            }
    }
}

// MARK: - Copy

/// Title and body for a reminder bundle.
///
/// Separate from the scheduler so the wording can be tested without the
/// notification center, and so every string goes through `L10n` — a
/// notification is the one surface the user reads outside the app, and it was
/// the last place still assembling display text by interpolation.
enum ServiceReminderCopy {

    /// How many services a bundled body names before it summarizes the rest.
    /// Past this the body is longer than a notification shows anyway, and a
    /// count reads better than a truncated list.
    static let maxNamedServices = 4

    static func title(for bundle: ServiceReminderBundle) -> String {
        guard bundle.count > 1 else {
            return singleTitle(serviceName: bundle.serviceNames.first ?? "", daysBeforeDue: bundle.daysBeforeDue)
        }
        return bundledTitle(count: bundle.count, daysBeforeDue: bundle.daysBeforeDue)
    }

    static func body(for bundle: ServiceReminderBundle, vehicleName: String) -> String {
        guard bundle.count > 1 else {
            return singleBody(
                vehicleName: vehicleName,
                serviceName: bundle.serviceNames.first ?? "",
                daysBeforeDue: bundle.daysBeforeDue
            )
        }
        return bundledBody(vehicleName: vehicleName, serviceNames: bundle.serviceNames)
    }

    // MARK: Snooze

    /// No lead time: a snooze arrives a day after the banner it replays, so
    /// "due today" or "in 7 days" would no longer be true.
    static func snoozeTitle(serviceNames: [String]) -> String {
        guard serviceNames.count > 1 else { return L10n.notificationSnoozeTitle(serviceNames.first ?? "") }
        return L10n.notificationSnoozeBundleTitle(serviceNames.count)
    }

    static func snoozeBody(serviceNames: [String], vehicleName: String) -> String {
        guard serviceNames.count > 1 else {
            return L10n.notificationSnoozeBody(vehicleName, serviceNames.first ?? "")
        }
        return bundledBody(vehicleName: vehicleName, serviceNames: serviceNames)
    }

    // MARK: Single service

    private static func singleTitle(serviceName: String, daysBeforeDue: Int) -> String {
        switch daysBeforeDue {
        case 0: return L10n.notificationServiceDueTitleToday(serviceName)
        case 1: return L10n.notificationServiceDueTitleTomorrow(serviceName)
        case 7: return L10n.notificationServiceDueTitleWeek(serviceName)
        case 30: return L10n.notificationServiceDueTitleMonth(serviceName)
        default: return L10n.notificationServiceDueTitleGeneric(serviceName)
        }
    }

    private static func singleBody(vehicleName: String, serviceName: String, daysBeforeDue: Int) -> String {
        switch daysBeforeDue {
        case 0: return L10n.notificationServiceDueBodyToday(vehicleName, serviceName)
        case 1: return L10n.notificationServiceDueBodyTomorrow(vehicleName, serviceName)
        case 7: return L10n.notificationServiceDueBodyWeek(vehicleName, serviceName)
        case 30: return L10n.notificationServiceDueBodyMonth(vehicleName, serviceName)
        default: return L10n.notificationServiceDueBodyGeneric(vehicleName, serviceName, daysBeforeDue)
        }
    }

    // MARK: Bundle

    private static func bundledTitle(count: Int, daysBeforeDue: Int) -> String {
        switch daysBeforeDue {
        case 0: return L10n.notificationBundleTitleToday(count)
        case 1: return L10n.notificationBundleTitleTomorrow(count)
        case 7: return L10n.notificationBundleTitleWeek(count)
        case 30: return L10n.notificationBundleTitleMonth(count)
        default: return L10n.notificationBundleTitleGeneric(count, daysBeforeDue)
        }
    }

    private static func bundledBody(vehicleName: String, serviceNames: [String]) -> String {
        let named = Array(serviceNames.prefix(maxNamedServices))
        // ListFormatter, not a hand-rolled join: the separator and the final
        // conjunction differ by language, and this is user-facing prose.
        let list = ListFormatter.localizedString(byJoining: named)
        let remaining = serviceNames.count - named.count

        guard remaining > 0 else {
            return L10n.notificationBundleBody(vehicleName, list)
        }
        return L10n.notificationBundleBodyOverflow(vehicleName, list, remaining)
    }
}
