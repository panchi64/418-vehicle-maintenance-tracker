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
    let vehicleName: String
    let currentMileage: Int
    let services: [WidgetService]
    let configuration: CheckpointWidgetConfigurationIntent

    static var placeholder: ServiceEntry {
        ServiceEntry(
            date: Date(),
            vehicleName: "My Vehicle",
            currentMileage: 34500,
            services: [
                WidgetService(name: "Oil Change", status: .dueSoon, dueDescription: "Due in 5 days", dueMileage: 35000, daysRemaining: 5),
                WidgetService(name: "Tire Rotation", status: .good, dueDescription: "Due in 30 days", dueMileage: 38000, daysRemaining: 30),
                WidgetService(name: "Brake Inspection", status: .overdue, dueDescription: "5 days overdue", dueMileage: 32000, daysRemaining: -5)
            ],
            configuration: CheckpointWidgetConfigurationIntent()
        )
    }

    static var empty: ServiceEntry {
        ServiceEntry(date: Date(), vehicleName: "No Vehicle", currentMileage: 0, services: [], configuration: CheckpointWidgetConfigurationIntent())
    }
}

// MARK: - Widget Service Model

struct WidgetService: Identifiable {
    let id = UUID()
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
    let vehicleName: String
    let currentMileage: Int
    let services: [SharedService]
    let updatedAt: Date

    struct SharedService: Codable {
        let name: String
        let status: WidgetServiceStatus
        let dueDescription: String
        let dueMileage: Int?        // The mileage when service is due
        let daysRemaining: Int?     // Days until due (negative = overdue)
    }

    /// Provide fallback for older data without currentMileage
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vehicleName = try container.decode(String.self, forKey: .vehicleName)
        currentMileage = try container.decodeIfPresent(Int.self, forKey: .currentMileage) ?? 0
        services = try container.decode([SharedService].self, forKey: .services)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case vehicleName, currentMileage, services, updatedAt
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
        // Load from UserDefaults in App Group
        guard let userDefaults = UserDefaults(suiteName: appGroupID),
              let data = userDefaults.data(forKey: widgetDataKey) else {
            return ServiceEntry(
                date: Date(),
                vehicleName: "No Vehicle",
                currentMileage: 0,
                services: [],
                configuration: configuration
            )
        }

        do {
            let widgetData = try JSONDecoder().decode(WidgetData.self, from: data)

            let widgetServices = widgetData.services.map { service in
                WidgetService(
                    name: service.name,
                    status: service.status,
                    dueDescription: service.dueDescription,
                    dueMileage: service.dueMileage,
                    daysRemaining: service.daysRemaining
                )
            }

            return ServiceEntry(
                date: Date(),
                vehicleName: widgetData.vehicleName,
                currentMileage: widgetData.currentMileage,
                services: widgetServices,
                configuration: configuration
            )
        } catch {
            print("Widget failed to decode data: \(error)")
            return ServiceEntry(
                date: Date(),
                vehicleName: "No Vehicle",
                currentMileage: 0,
                services: [],
                configuration: configuration
            )
        }
    }
}
