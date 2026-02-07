//
//  WatchWidgetProvider.swift
//  CheckpointWatchWidget
//
//  Timeline provider for Watch complications — reads from watch App Group UserDefaults
//  Uses TimelineProvider (not AppIntentTimelineProvider) — no per-complication vehicle selection
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WatchWidgetEntry: TimelineEntry {
    let date: Date
    let vehicleName: String
    let currentMileage: Int
    let service: WatchWidgetService?
    let isStale: Bool

    static var placeholder: WatchWidgetEntry {
        WatchWidgetEntry(
            date: Date(),
            vehicleName: "MY VEHICLE",
            currentMileage: 34500,
            service: WatchWidgetService(
                name: "Oil Change",
                status: .dueSoon,
                dueDescription: "Due in 5 days",
                dueMileage: 35000,
                daysRemaining: 5
            ),
            isStale: false
        )
    }

    static var empty: WatchWidgetEntry {
        WatchWidgetEntry(
            date: Date(),
            vehicleName: "",
            currentMileage: 0,
            service: nil,
            isStale: false
        )
    }
}

// MARK: - Widget Service Model

struct WatchWidgetService {
    let name: String
    let status: WatchWidgetStatus
    let dueDescription: String
    let dueMileage: Int?
    let daysRemaining: Int?
}

enum WatchWidgetStatus: String, Codable {
    case overdue, dueSoon, good, neutral

    var color: Color {
        switch self {
        case .overdue: return WatchWidgetColors.statusOverdue
        case .dueSoon: return WatchWidgetColors.statusDueSoon
        case .good: return WatchWidgetColors.statusGood
        case .neutral: return WatchWidgetColors.statusNeutral
        }
    }

    var icon: String {
        switch self {
        case .overdue: return "exclamationmark.triangle"
        case .dueSoon: return "clock"
        case .good: return "checkmark.circle"
        case .neutral: return "minus.circle"
        }
    }
}

// MARK: - Shared Data (matches Watch app's WatchVehicleData format)

private struct WatchWidgetData: Codable {
    let vehicleID: String
    let vehicleName: String
    let currentMileage: Int
    let estimatedMileage: Int?
    let isEstimated: Bool
    let services: [WatchWidgetSharedService]
    let updatedAt: Date

    var isStale: Bool {
        Date().timeIntervalSince(updatedAt) > 3600
    }
}

private struct WatchWidgetSharedService: Codable {
    let vehicleID: String
    let name: String
    let status: String
    let dueDescription: String
    let dueMileage: Int?
    let daysRemaining: Int?
}

// MARK: - Timeline Provider

struct WatchWidgetProvider: TimelineProvider {
    typealias Entry = WatchWidgetEntry

    private let appGroupID = "group.com.418-studio.checkpoint.watch"
    private let vehicleDataKey = "watchVehicleData"

    func placeholder(in context: Context) -> WatchWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(loadEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Load Data

    private func loadEntry() -> WatchWidgetEntry {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: vehicleDataKey) else {
            return .empty
        }

        do {
            let vehicleData = try JSONDecoder().decode(WatchWidgetData.self, from: data)

            let firstService = vehicleData.services.first.map { service in
                WatchWidgetService(
                    name: service.name,
                    status: mapStatus(service.status),
                    dueDescription: service.dueDescription,
                    dueMileage: service.dueMileage,
                    daysRemaining: service.daysRemaining
                )
            }

            return WatchWidgetEntry(
                date: Date(),
                vehicleName: vehicleData.vehicleName,
                currentMileage: vehicleData.currentMileage,
                service: firstService,
                isStale: vehicleData.isStale
            )
        } catch {
            return .empty
        }
    }

    private func mapStatus(_ statusString: String) -> WatchWidgetStatus {
        switch statusString.lowercased() {
        case "overdue": return .overdue
        case "duesoon": return .dueSoon
        case "good": return .good
        default: return .neutral
        }
    }
}
