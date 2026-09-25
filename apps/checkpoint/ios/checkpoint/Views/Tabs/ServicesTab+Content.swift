//
//  ServicesTab+Content.swift
//  checkpoint
//
//  Everything the Services list shows, derived in one pass (Views/CLAUDE.md,
//  "Derive a screen's data once per body"). Kept apart from the view so the
//  grouping and search rules are testable without rendering anything.
//

import Foundation

struct ServicesTabContent {

    /// One status group: Overdue, Due Soon or On Track. A group with no items
    /// is never built — "Overdue: nothing" would be an apology line on the
    /// happiest possible screen — but the order of those that remain is fixed.
    struct StatusGroup: Identifiable {
        let status: ServiceStatus
        let services: [Service]
        var id: String { "\(status)" }
    }

    /// One calendar month of history, newest month first.
    struct MonthGroup: Identifiable {
        /// First instant of the month; also the identity.
        let month: Date
        let logs: [ServiceLog]
        var id: Date { month }
    }

    /// The status groups, in the order they render.
    static let groupOrder: [ServiceStatus] = [.overdue, .dueSoon, .good]

    let statusGroups: [StatusGroup]
    let months: [MonthGroup]
    let mileage: MileageEstimate

    var isEmpty: Bool { statusGroups.isEmpty && months.isEmpty }

    /// Every service shown, for resolving a selection.
    var services: [Service] { statusGroups.flatMap(\.services) }
    var logs: [ServiceLog] { months.flatMap(\.logs) }

    static let empty = ServicesTabContent(
        statusGroups: [],
        months: [],
        mileage: MileageEstimate(pace: nil, effective: 0, isEstimated: false)
    )

    /// - Parameters:
    ///   - services: the vehicle's services, already scoped by the query.
    ///   - logs: the vehicle's logs, newest first from the query.
    ///   - searchText: narrows both halves of the list — the search field sits
    ///     above the whole tab.
    @MainActor
    static func make(
        services: [Service],
        logs: [ServiceLog],
        mileage: MileageEstimate,
        searchText: String,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> ServicesTabContent {
        // Only tracked services have a status. Log-only ones (and services the
        // user stopped tracking) are history, not schedule.
        let tracked = services
            .filter(\.hasDueTracking)
            .filter { matches($0, searchText) }
            .sortedByUrgency(mileage)

        // One status classification per service.
        var byStatus: [ServiceStatus: [Service]] = [:]
        for service in tracked {
            byStatus[service.status(currentMileage: mileage.effective, currentDate: now), default: []]
                .append(service)
        }
        let groups = groupOrder.compactMap { status -> StatusGroup? in
            guard let items = byStatus[status], !items.isEmpty else { return nil }
            return StatusGroup(status: status, services: items)
        }

        return ServicesTabContent(
            statusGroups: groups,
            months: monthGroups(logs.filter { matches($0, searchText) }, calendar: calendar),
            mileage: mileage
        )
    }

    /// Groups newest-first logs by calendar month, keeping their order.
    static func monthGroups(_ logs: [ServiceLog], calendar: Calendar) -> [MonthGroup] {
        var groups: [MonthGroup] = []
        var currentMonth: Date?
        var bucket: [ServiceLog] = []
        for log in logs {
            let month = calendar.dateInterval(of: .month, for: log.performedDate)?.start ?? log.performedDate
            if month != currentMonth {
                if let currentMonth, !bucket.isEmpty {
                    groups.append(MonthGroup(month: currentMonth, logs: bucket))
                }
                currentMonth = month
                bucket = []
            }
            bucket.append(log)
        }
        if let currentMonth, !bucket.isEmpty {
            groups.append(MonthGroup(month: currentMonth, logs: bucket))
        }
        return groups
    }

    // MARK: - Search

    static func matches(_ service: Service, _ searchText: String) -> Bool {
        searchText.isEmpty || service.name.localizedCaseInsensitiveContains(searchText)
    }

    /// Service name, notes, and receipt OCR text.
    static func matches(_ log: ServiceLog, _ searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        if log.service?.name.localizedCaseInsensitiveContains(searchText) ?? false { return true }
        if log.notes?.localizedCaseInsensitiveContains(searchText) ?? false { return true }
        return (log.attachments ?? []).contains {
            $0.extractedText?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
}
