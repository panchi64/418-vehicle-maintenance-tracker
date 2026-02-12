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
                WidgetService(serviceID: nil, name: "Oil Change", status: .dueSoon, dueDescription: "Due in 5 days", dueMileage: 35000, daysRemaining: 5),
                WidgetService(serviceID: nil, name: "Tire Rotation", status: .good, dueDescription: "Due in 30 days", dueMileage: 38000, daysRemaining: 30),
                WidgetService(serviceID: nil, name: "Brake Inspection", status: .overdue, dueDescription: "5 days overdue", dueMileage: 32000, daysRemaining: -5)
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

    // App Group container identifier
    private let appGroupID = "group.com.418-studio.checkpoint.shared"
    private let widgetDataKey = "widgetData"

    func placeholder(in context: Context) -> ServiceEntry {
        ServiceEntry.placeholder
    }

    func snapshot(for configuration: CheckpointWidgetConfigurationIntent, in context: Context) async -> ServiceEntry {
        if context.isPreview {
            return ServiceEntry.placeholder
        } else {
            return loadEntry(configuration: configuration)
        }
    }

    func timeline(for configuration: CheckpointWidgetConfigurationIntent, in context: Context) async -> Timeline<ServiceEntry> {
        let entry = loadEntry(configuration: configuration)

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func loadEntry(configuration: CheckpointWidgetConfigurationIntent) -> ServiceEntry {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            return makeEmptyEntry(configuration: configuration)
        }

        // Load pending completion IDs to filter out already-logged services
        let pendingIDs = Set(PendingWidgetCompletion.loadAll().map { $0.serviceID })

        // Resolve distance unit from intent (single source of truth)
        let resolvedUnit = configuration.distanceUnit.resolve()

        // Determine which vehicle to load:
        // - "match-app" or nil → use widgetData key (app's current selection)
        // - Specific vehicle → use per-vehicle key, fallback to widgetData
        let isMatchApp = configuration.vehicle == nil || configuration.vehicle?.id == "match-app"

        if !isMatchApp, let configuredVehicle = configuration.vehicle {
            // Explicit per-widget vehicle selection
            let vehicleKey = "widgetData_\(configuredVehicle.id)"
            if let data = userDefaults.data(forKey: vehicleKey),
               let entry = decodeEntry(from: data, configuration: configuration, distanceUnit: resolvedUnit, pendingIDs: pendingIDs) {
                return entry
            }
        }

        // Use the widgetData key (app's currently selected vehicle)
        if let data = userDefaults.data(forKey: widgetDataKey),
           let entry = decodeEntry(from: data, configuration: configuration, distanceUnit: resolvedUnit, pendingIDs: pendingIDs) {
            return entry
        }

        return makeEmptyEntry(configuration: configuration, distanceUnit: resolvedUnit)
    }

    private func decodeEntry(from data: Data, configuration: CheckpointWidgetConfigurationIntent, distanceUnit: WidgetDistanceUnit, pendingIDs: Set<String>) -> ServiceEntry? {
        do {
            let widgetData = try JSONDecoder().decode(WidgetData.self, from: data)

            // Filter out services that have pending completions so the widget
            // advances to the next service immediately after marking one done
            let widgetServices = widgetData.services.compactMap { service -> WidgetService? in
                if let serviceID = service.serviceID, pendingIDs.contains(serviceID) {
                    return nil
                }
                return WidgetService(
                    serviceID: service.serviceID,
                    name: service.name,
                    status: service.status,
                    dueDescription: service.dueDescription,
                    dueMileage: service.dueMileage,
                    daysRemaining: service.daysRemaining
                )
            }

            return ServiceEntry(
                date: Date(),
                vehicleID: widgetData.vehicleID,
                vehicleName: widgetData.vehicleName,
                currentMileage: widgetData.currentMileage,
                services: widgetServices,
                configuration: configuration,
                distanceUnit: distanceUnit
            )
        } catch {
            print("Widget failed to decode data: \(error)")
            return nil
        }
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
