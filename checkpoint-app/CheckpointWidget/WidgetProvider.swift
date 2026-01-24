//
//  WidgetProvider.swift
//  CheckpointWidget
//
//  Timeline provider for widget data
//

import WidgetKit
import SwiftUI
import SwiftData

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

enum WidgetServiceStatus {
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

// MARK: - Timeline Provider

struct WidgetProvider: TimelineProvider {
    // App Group container identifier
    private let appGroupID = "group.com.checkpoint.shared"

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
        // Try to load from shared SwiftData container
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return ServiceEntry.empty
        }

        let storeURL = containerURL.appendingPathComponent("checkpoint.store")

        do {
            let schema = Schema([Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self])
            let config = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [config])

            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Vehicle>()
            let vehicles = try context.fetch(descriptor)

            guard let vehicle = vehicles.first else {
                return ServiceEntry.empty
            }

            // Sort services by urgency (most urgent first)
            let sortedServices = vehicle.services.sorted {
                $0.urgencyScore(currentMileage: vehicle.currentMileage) < $1.urgencyScore(currentMileage: vehicle.currentMileage)
            }

            // Map to widget services
            let widgetServices = sortedServices.prefix(3).map { service in
                let status = service.status(currentMileage: vehicle.currentMileage)
                return WidgetService(
                    name: service.name,
                    status: mapStatus(status),
                    dueDescription: service.dueDescription ?? "Scheduled"
                )
            }

            return ServiceEntry(
                date: Date(),
                vehicleName: vehicle.displayName,
                services: Array(widgetServices)
            )
        } catch {
            print("Widget failed to load data: \(error)")
            return ServiceEntry.empty
        }
    }

    private func mapStatus(_ status: ServiceStatus) -> WidgetServiceStatus {
        switch status {
        case .overdue: return .overdue
        case .dueSoon: return .dueSoon
        case .good: return .good
        case .neutral: return .neutral
        }
    }
}
