//
//  WidgetProvider.swift
//  CheckpointWidget
//
//  Timeline provider for widget data using App Group shared data
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry

struct ServiceEntry: TimelineEntry {
    let date: Date
    let vehicleID: String?
    let vehicleName: String
    let currentMileage: Int
    let services: [WidgetService]
    let configuration: CheckpointWidgetConfigurationIntent
    let distanceUnit: WidgetDistanceUnit

    static var placeholder: ServiceEntry {
        ServiceEntry(
            date: Date(),
            vehicleID: nil,
            vehicleName: "My Vehicle",
            currentMileage: 34500,
            services: [
                WidgetService(serviceID: nil, name: "Oil Change", status: .dueSoon, dueDescription: "or 1,200 miles", dueMileage: 35000, daysRemaining: 5, duePeriod: "This week"),
                WidgetService(serviceID: nil, name: "Tire Rotation", status: .good, dueDescription: "or 3,800 miles", dueMileage: 38000, daysRemaining: 30, duePeriod: "Early Jul"),
                WidgetService(serviceID: nil, name: "Brake Inspection", status: .overdue, dueDescription: "500 miles overdue", dueMileage: 32000, daysRemaining: -5, duePeriod: "Overdue")
            ],
            configuration: CheckpointWidgetConfigurationIntent(),
            distanceUnit: WidgetDistanceUnit.current()
        )
    }

    static var empty: ServiceEntry {
        ServiceEntry(date: Date(), vehicleID: nil, vehicleName: "No Vehicle", currentMileage: 0, services: [], configuration: CheckpointWidgetConfigurationIntent(), distanceUnit: WidgetDistanceUnit.current())
    }
}

// MARK: - Widget Service Model

struct WidgetService: Identifiable {
    let id = UUID()
    let serviceID: String?      // UUID string of the Service entity (nil for marbete)
    let name: String
    let status: WidgetServiceStatus
    let dueDescription: String
    let dueMileage: Int?        // The mileage when service is due
    let daysRemaining: Int?     // Days until due (negative = overdue)
    let duePeriod: String?      // Abstracted month period for date-based hero (e.g. "Mid May")
}

enum WidgetServiceStatus: String, Codable {
    case overdue, dueSoon, good, neutral

    var color: Color {
        switch self {
        case .overdue: return WidgetColors.statusOverdue
        case .dueSoon: return WidgetColors.statusDueSoon
        case .good: return WidgetColors.statusGood
        case .neutral: return WidgetColors.statusNeutral
        }
    }

    /// Color for accessory (lock screen) widgets - uses system colors for tinting
    var accessoryColor: Color {
        switch self {
        case .overdue: return .red
        case .dueSoon: return .yellow
        case .good: return .green
        case .neutral: return .gray
        }
    }
}

// MARK: - Shared Data Structure

/// Data structure for sharing between main app and widget via UserDefaults
struct WidgetData: Codable {
    let vehicleID: String?
    let vehicleName: String
    let currentMileage: Int
    let services: [SharedService]
    let updatedAt: Date

    struct SharedService: Codable {
        let serviceID: String?      // UUID string of the Service entity (nil for marbete)
        let name: String
        let status: WidgetServiceStatus
        let dueDescription: String
        let dueMileage: Int?        // The mileage when service is due
        let daysRemaining: Int?     // Days until due (negative = overdue)
        let duePeriod: String?      // Abstracted month period for date-based hero (e.g. "Mid May")
        // Raw due date for date-based rows. Optional so snapshots written before
        // this field shipped still decode (older data falls back to the
        // precomputed daysRemaining/duePeriod/dueDescription above). Optional
        // Codable properties decode as nil when the key is absent.
        let dueDate: Date?
    }

    /// Provide fallback for older data without currentMileage or vehicleID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vehicleID = try container.decodeIfPresent(String.self, forKey: .vehicleID)
        vehicleName = try container.decode(String.self, forKey: .vehicleName)
        currentMileage = try container.decodeIfPresent(Int.self, forKey: .currentMileage) ?? 0
        services = try container.decode([SharedService].self, forKey: .services)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case vehicleID, vehicleName, currentMileage, services, updatedAt
    }
}

// MARK: - Timeline Provider

struct WidgetProvider: AppIntentTimelineProvider {
    typealias Entry = ServiceEntry
    typealias Intent = CheckpointWidgetConfigurationIntent

    /// How many day-boundary entries to project ahead so date-based countdowns
    /// advance ("in 3 days" → "in 2 days", "This week" → "Overdue") without the
    /// app running. One week of daily transitions.
    private let projectedDays = 7

    func placeholder(in context: Context) -> ServiceEntry {
        ServiceEntry.placeholder
    }

    func snapshot(for configuration: CheckpointWidgetConfigurationIntent, in context: Context) async -> ServiceEntry {
        if context.isPreview {
            return ServiceEntry.placeholder
        }
        guard let snapshot = loadSnapshot(configuration: configuration) else {
            return makeEmptyEntry(configuration: configuration)
        }
        return makeEntry(from: snapshot, at: Date(), configuration: configuration)
    }

    func timeline(for configuration: CheckpointWidgetConfigurationIntent, in context: Context) async -> Timeline<ServiceEntry> {
        guard let snapshot = loadSnapshot(configuration: configuration) else {
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            return Timeline(entries: [makeEmptyEntry(configuration: configuration)], policy: .after(nextUpdate))
        }

        // Recompute each date-based row against every entry's date so the
        // displayed countdown/period stays live between app writes, rather than
        // re-rendering the same precomputed values the app baked in at write time.
        let entries = timelineEntryDates(from: Date()).map { date in
            makeEntry(from: snapshot, at: date, configuration: configuration)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    // MARK: - Snapshot loading

    /// Decoded snapshot plus the derived context needed to render an entry.
    private struct LoadedSnapshot {
        let data: WidgetData
        let distanceUnit: WidgetDistanceUnit
        let pendingIDs: Set<String>
    }

    /// Resolve which vehicle's JSON to show and decode it once. The per-entry
    /// recompute in `makeEntry` then works off this single decode.
    private func loadSnapshot(configuration: CheckpointWidgetConfigurationIntent) -> LoadedSnapshot? {
        guard let userDefaults = WidgetAppGroup.defaults() else { return nil }

        // Load pending completion IDs to filter out already-logged services
        let pendingIDs = Set(PendingWidgetCompletion.loadAll().map { $0.serviceID })

        // Resolve distance unit from intent (single source of truth)
        let resolvedUnit = configuration.distanceUnit.resolve()

        func decode(_ data: Data) -> WidgetData? {
            do {
                return try JSONDecoder().decode(WidgetData.self, from: data)
            } catch {
                print("Widget failed to decode data: \(error)")
                return nil
            }
        }

        // Determine which vehicle to load:
        // - "match-app" or nil → use widgetData key (app's current selection)
        // - Specific vehicle → use per-vehicle key, fallback to widgetData
        let isMatchApp = configuration.vehicle == nil || configuration.vehicle?.id == "match-app"

        if !isMatchApp, let configuredVehicle = configuration.vehicle {
            let vehicleKey = "\(WidgetAppGroup.widgetDataKeyPrefix)\(configuredVehicle.id)"
            if let data = userDefaults.data(forKey: vehicleKey), let decoded = decode(data) {
                return LoadedSnapshot(data: decoded, distanceUnit: resolvedUnit, pendingIDs: pendingIDs)
            }
        }

        if let data = userDefaults.data(forKey: WidgetAppGroup.widgetDataKey), let decoded = decode(data) {
            return LoadedSnapshot(data: decoded, distanceUnit: resolvedUnit, pendingIDs: pendingIDs)
        }

        return nil
    }

    /// The entry dates for the timeline: now plus each of the next N local
    /// midnights, so the day count and period bucket roll over at midnight.
    private func timelineEntryDates(from now: Date, calendar: Calendar = .current) -> [Date] {
        var dates = [now]
        guard let firstMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return dates
        }
        for offset in 0..<projectedDays {
            if let date = calendar.date(byAdding: .day, value: offset, to: firstMidnight) {
                dates.append(date)
            }
        }
        return dates
    }

    // MARK: - Entry construction

    /// Build a `ServiceEntry` for `entryDate`, recomputing each date-based row's
    /// countdown, period, and status against that date. Mileage-based rows are
    /// left as stored (mileage doesn't advance without an app write).
    private func makeEntry(from snapshot: LoadedSnapshot, at entryDate: Date, configuration: CheckpointWidgetConfigurationIntent) -> ServiceEntry {
        let widgetServices = snapshot.data.services.compactMap { service -> WidgetService? in
            // Filter out services with pending completions so the widget advances
            // to the next service immediately after marking one done.
            if let serviceID = service.serviceID, snapshot.pendingIDs.contains(serviceID) {
                return nil
            }
            return recomputedService(service, at: entryDate)
        }

        return ServiceEntry(
            date: entryDate,
            vehicleID: snapshot.data.vehicleID,
            vehicleName: snapshot.data.vehicleName,
            currentMileage: snapshot.data.currentMileage,
            services: widgetServices,
            configuration: configuration,
            distanceUnit: snapshot.distanceUnit
        )
    }

    /// Re-derive a row's time-relative fields against `entryDate`. Rows with a
    /// mileage target (or no raw due date, e.g. older snapshots) pass through
    /// unchanged; date-based rows recompute days/period/description/status from
    /// the stored `dueDate` so the countdown never freezes.
    private func recomputedService(_ service: WidgetData.SharedService, at entryDate: Date) -> WidgetService {
        guard service.dueMileage == nil, let dueDate = service.dueDate else {
            return WidgetService(
                serviceID: service.serviceID,
                name: service.name,
                status: service.status,
                dueDescription: service.dueDescription,
                dueMileage: service.dueMileage,
                daysRemaining: service.daysRemaining,
                duePeriod: service.duePeriod
            )
        }

        let calendar = Calendar.current
        let period = DuePeriodFormatter.describe(dueDate, relativeTo: entryDate, calendar: calendar)
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: entryDate),
            to: calendar.startOfDay(for: dueDate)
        ).day

        // A marbete row (no serviceID) reads "Expires …/Expired"; services read
        // "Due …/Overdue". Distinguishing on serviceID keeps the accessory
        // dueDescription verb correct after recompute.
        let isMarbete = service.serviceID == nil
        let dueDescription = period.phrased(
            format: isMarbete ? "Expires %@" : "Due %@",
            overdueWord: isMarbete ? "Expired" : "Overdue"
        )

        // Once the date passes, an item is overdue regardless of the status the
        // app baked in, so flip stale "due soon" chips to overdue.
        let status: WidgetServiceStatus = period.isOverdue ? .overdue : service.status

        return WidgetService(
            serviceID: service.serviceID,
            name: service.name,
            status: status,
            dueDescription: dueDescription,
            dueMileage: nil,
            daysRemaining: days,
            duePeriod: period.label
        )
    }

    private func makeEmptyEntry(configuration: CheckpointWidgetConfigurationIntent, distanceUnit: WidgetDistanceUnit = .miles) -> ServiceEntry {
        ServiceEntry(
            date: Date(),
            vehicleID: nil,
            vehicleName: "No Vehicle",
            currentMileage: 0,
            services: [],
            configuration: configuration,
            distanceUnit: distanceUnit
        )
    }
}
