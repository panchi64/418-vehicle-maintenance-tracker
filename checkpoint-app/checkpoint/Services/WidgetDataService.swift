//
//  WidgetDataService.swift
//  checkpoint
//
//  Service for sharing data with the home screen widget via App Groups
//

import Foundation
import WidgetKit

/// Service for updating widget data in the shared App Group container
class WidgetDataService {
    static let shared = WidgetDataService()

    private let appGroupID = "group.com.418-studio.checkpoint.shared"
    private let widgetDataKey = "widgetData"

    private init() {}

    /// Update the widget with current vehicle and service data
    /// - Parameters:
    ///   - vehicle: The current vehicle to display
    ///   - services: The services to display (should be sorted by urgency)
    ///   - currentMileage: The vehicle's current mileage for relative calculations
    ///   - estimatedMileage: Optional estimated mileage based on pace data
    ///   - isEstimated: Whether the displayed mileage is estimated
    func updateWidgetData(
        vehicleName: String,
        currentMileage: Int,
        estimatedMileage: Int? = nil,
        isEstimated: Bool = false,
        services: [(name: String, status: String, dueDescription: String, dueMileage: Int?, daysRemaining: Int?)]
    ) {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            print("Failed to access App Group UserDefaults")
            return
        }

        let sharedServices = services.prefix(3).map { service in
            WidgetSharedData.SharedService(
                name: service.name,
                status: mapStatus(service.status),
                dueDescription: service.dueDescription,
                dueMileage: service.dueMileage,
                daysRemaining: service.daysRemaining
            )
        }

        let widgetData = WidgetSharedData(
            vehicleName: vehicleName,
            currentMileage: currentMileage,
            estimatedMileage: estimatedMileage,
            isEstimatedMileage: isEstimated,
            services: Array(sharedServices),
            updatedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(widgetData)
            userDefaults.set(data, forKey: widgetDataKey)

            // Reload widget timelines
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to encode widget data: \(error)")
        }
    }

    /// Update widget from a Vehicle and its services
    func updateWidget(for vehicle: Vehicle) {
        let effectiveMileage = vehicle.effectiveMileage
        let pace = vehicle.dailyMilesPace

        let sortedServices = vehicle.services.sorted {
            $0.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace) < $1.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace)
        }

        let serviceData = sortedServices.map { service -> (name: String, status: String, dueDescription: String, dueMileage: Int?, daysRemaining: Int?) in
            let status = service.status(currentMileage: effectiveMileage)
            let statusString: String
            switch status {
            case .overdue: statusString = "overdue"
            case .dueSoon: statusString = "dueSoon"
            case .good: statusString = "good"
            case .neutral: statusString = "neutral"
            }

            // Calculate days remaining from effective due date (considering pace)
            let daysRemaining: Int?
            if let effectiveDue = service.effectiveDueDate(currentMileage: effectiveMileage, dailyPace: pace) {
                daysRemaining = Calendar.current.dateComponents([.day], from: .now, to: effectiveDue).day ?? 0
            } else {
                daysRemaining = nil
            }

            return (
                name: service.name,
                status: statusString,
                dueDescription: service.primaryDescription ?? "Scheduled",
                dueMileage: service.dueMileage,
                daysRemaining: daysRemaining
            )
        }

        updateWidgetData(
            vehicleName: vehicle.displayName,
            currentMileage: vehicle.currentMileage,
            estimatedMileage: vehicle.estimatedMileage,
            isEstimated: vehicle.isUsingEstimatedMileage,
            services: serviceData
        )
    }

    /// Clear widget data
    func clearWidgetData() {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else { return }
        userDefaults.removeObject(forKey: widgetDataKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func mapStatus(_ statusString: String) -> WidgetSharedData.ServiceStatus {
        switch statusString.lowercased() {
        case "overdue": return .overdue
        case "duesoon": return .dueSoon
        case "good": return .good
        default: return .neutral
        }
    }
}

// MARK: - Shared Data Structures

/// Data structure matching the widget's expected format
struct WidgetSharedData: Codable {
    let vehicleName: String
    let currentMileage: Int
    let estimatedMileage: Int?
    let isEstimatedMileage: Bool
    let services: [SharedService]
    let updatedAt: Date

    struct SharedService: Codable {
        let name: String
        let status: ServiceStatus
        let dueDescription: String
        let dueMileage: Int?        // The mileage when service is due (e.g., 35000)
        let daysRemaining: Int?     // Days until due (negative = overdue)
    }

    enum ServiceStatus: String, Codable {
        case overdue, dueSoon, good, neutral
    }
}

