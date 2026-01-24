//
//  WidgetProvider.swift
//  CheckpointWidget
//
//  Timeline provider for widget data using App Group shared data
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ServiceEntry: TimelineEntry {
    let date: Date
    let vehicleName: String
    let services: [WidgetService]

    static var placeholder: ServiceEntry {
        ServiceEntry(
            date: Date(),
            vehicleName: "My Vehicle",
            services: [
                WidgetService(name: "Oil Change", status: .dueSoon, dueDescription: "Due in 5 days"),
                WidgetService(name: "Tire Rotation", status: .good, dueDescription: "Due in 30 days"),
                WidgetService(name: "Brake Inspection", status: .overdue, dueDescription: "5 days overdue")
            ]
        )
    }

    static var empty: ServiceEntry {
        ServiceEntry(date: Date(), vehicleName: "No Vehicle", services: [])
    }
}

// MARK: - Widget Service Model

struct WidgetService: Identifiable {
    let id = UUID()
    let name: String
    let status: WidgetServiceStatus
    let dueDescription: String
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
}

// MARK: - Shared Data Structure

/// Data structure for sharing between main app and widget via UserDefaults
struct WidgetData: Codable {
    let vehicleName: String
    let services: [SharedService]
    let updatedAt: Date

    struct SharedService: Codable {
        let name: String
        let status: WidgetServiceStatus
        let dueDescription: String
    }
}

// MARK: - Timeline Provider

struct WidgetProvider: TimelineProvider {
    // App Group container identifier
    private let appGroupID = "group.com.checkpoint.shared"
    private let widgetDataKey = "widgetData"

    func placeholder(in context: Context) -> ServiceEntry {
        ServiceEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ServiceEntry) -> Void) {
        if context.isPreview {
            completion(ServiceEntry.placeholder)
        } else {
            let entry = loadEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ServiceEntry>) -> Void) {
        let entry = loadEntry()

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> ServiceEntry {
        // Load from UserDefaults in App Group
        guard let userDefaults = UserDefaults(suiteName: appGroupID),
              let data = userDefaults.data(forKey: widgetDataKey) else {
            return ServiceEntry.empty
        }

        do {
            let widgetData = try JSONDecoder().decode(WidgetData.self, from: data)

            let widgetServices = widgetData.services.map { service in
                WidgetService(
                    name: service.name,
                    status: service.status,
                    dueDescription: service.dueDescription
                )
            }

            return ServiceEntry(
                date: Date(),
                vehicleName: widgetData.vehicleName,
                services: widgetServices
            )
        } catch {
            print("Widget failed to decode data: \(error)")
            return ServiceEntry.empty
        }
    }
}
