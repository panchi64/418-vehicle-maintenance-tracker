//
//  WidgetDataService.swift
//  checkpoint
//
//  Service for sharing data with the home screen widget via App Groups
//

import Foundation
import SwiftData
import WidgetKit
import Combine
import CoreData
import os

private let widgetLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "Widget")

/// Service for updating widget data in the shared App Group container
@MainActor
final class WidgetDataService {
    static let shared = WidgetDataService()

    private let widgetDataKey = "widgetData"
    private let vehicleListKey = "vehicleList"

    /// Cancellables for observation
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Observe remote change notifications from CloudKit sync
        setupRemoteChangeObserver()
    }

    // MARK: - CloudKit Remote Change Handling

    /// Set up observer for remote changes from CloudKit
    private func setupRemoteChangeObserver() {
        NotificationCenter.default.publisher(
            for: .NSPersistentStoreRemoteChange
        )
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.handleRemoteChange()
        }
        .store(in: &cancellables)
    }

    /// Handle remote changes by reloading widgets
    private func handleRemoteChange() {
        // Reload all widget timelines to reflect remote changes
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Returns the vehicle-specific widget data key
    private func widgetDataKey(for vehicleID: String) -> String {
        "widgetData_\(vehicleID)"
    }

    /// Update the widget with current vehicle and service data
    /// - Parameters:
    ///   - vehicleID: The vehicle's UUID string for vehicle-specific storage
    ///   - vehicleName: The vehicle's display name
    ///   - currentMileage: The vehicle's current mileage for relative calculations
    ///   - estimatedMileage: Optional estimated mileage based on pace data
    ///   - isEstimated: Whether the displayed mileage is estimated
    ///   - services: The services to display (should be sorted by urgency)
    func updateWidgetData(
        vehicleID: String,
        vehicleName: String,
        currentMileage: Int,
        estimatedMileage: Int? = nil,
        isEstimated: Bool = false,
        services: [(serviceID: String?, name: String, status: String, dueDescription: String, dueMileage: Int?, daysRemaining: Int?)]
    ) {
        guard let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget) else {
            widgetLogger.error("Failed to access App Group UserDefaults")
            return
        }

        let sharedServices = services.prefix(3).map { service in
            WidgetSharedData.SharedService(
                serviceID: service.serviceID,
                name: service.name,
                status: mapStatus(service.status),
                dueDescription: service.dueDescription,
                dueMileage: service.dueMileage,
                daysRemaining: service.daysRemaining
            )
        }

        let widgetData = WidgetSharedData(
            vehicleID: vehicleID,
            vehicleName: vehicleName,
            currentMileage: currentMileage,
            estimatedMileage: estimatedMileage,
            isEstimatedMileage: isEstimated,
            services: Array(sharedServices),
            updatedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(widgetData)
            // Store with vehicle-specific key
            userDefaults.set(data, forKey: widgetDataKey(for: vehicleID))
            // Also store with legacy key for backward compatibility
            userDefaults.set(data, forKey: widgetDataKey)

            // Reload widget timelines
            WidgetCenter.shared.reloadAllTimelines()

            // Send to Apple Watch
            WatchSessionService.shared.sendVehicleData(
                vehicleID: vehicleID,
                vehicleName: vehicleName,
                currentMileage: currentMileage,
                estimatedMileage: estimatedMileage,
                isEstimated: isEstimated,
                services: services
            )
        } catch {
            widgetLogger.error("Failed to encode widget data: \(error.localizedDescription)")
        }
    }

    /// Update widget from a Vehicle and its services (including marbete if configured)
    func updateWidget(for vehicle: Vehicle) {
        let effectiveMileage = vehicle.effectiveMileage
        let pace = vehicle.dailyMilesPace

        // Create service items
        var allItems: [(serviceID: String?, name: String, status: String, dueDescription: String, dueMileage: Int?, daysRemaining: Int?, urgencyScore: Int)] = (vehicle.services ?? []).map { service in
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
                serviceID: service.id.uuidString,
                name: service.name,
                status: statusString,
                dueDescription: service.primaryDescription ?? "Scheduled",
                dueMileage: service.dueMileage,
                daysRemaining: daysRemaining,
                urgencyScore: service.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace)
            )
        }

        // Add marbete if configured
        if vehicle.hasMarbeteExpiration {
            let marbeteStatus = vehicle.marbeteStatus
            let statusString: String
            switch marbeteStatus {
            case .overdue: statusString = "overdue"
            case .dueSoon: statusString = "dueSoon"
            case .good: statusString = "good"
            case .neutral: statusString = "neutral"
            }

            let daysRemaining = vehicle.daysUntilMarbeteExpiration
            let dueDescription: String
            if let days = daysRemaining {
                if days < 0 {
                    dueDescription = "\(abs(days)) days expired"
                } else if days == 0 {
                    dueDescription = "Expires today"
                } else if days == 1 {
                    dueDescription = "Expires tomorrow"
                } else {
                    dueDescription = "\(days) days remaining"
                }
            } else {
                dueDescription = vehicle.marbeteExpirationFormatted ?? "Set"
            }

            allItems.append((
                serviceID: nil,
                name: "Marbete Renewal",
                status: statusString,
                dueDescription: dueDescription,
                dueMileage: nil,  // Marbete has no mileage component
                daysRemaining: daysRemaining,
                urgencyScore: vehicle.marbeteUrgencyScore
            ))
        }

        // Sort all items by urgency score
        let sortedItems = allItems.sorted { $0.urgencyScore < $1.urgencyScore }

        // Convert to service data format (dropping urgencyScore)
        let serviceData = sortedItems.map { item in
            (serviceID: item.serviceID, name: item.name, status: item.status, dueDescription: item.dueDescription, dueMileage: item.dueMileage, daysRemaining: item.daysRemaining)
        }

        updateWidgetData(
            vehicleID: vehicle.id.uuidString,
            vehicleName: vehicle.displayName,
            currentMileage: vehicle.currentMileage,
            estimatedMileage: vehicle.estimatedMileage,
            isEstimated: vehicle.isUsingEstimatedMileage,
            services: serviceData
        )
    }

    /// Update the list of vehicles available for widget selection
    /// - Parameter vehicles: All vehicles to make available in widget configuration
    func updateVehicleList(_ vehicles: [Vehicle]) {
        guard let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget) else {
            widgetLogger.error("Failed to access App Group UserDefaults")
            return
        }

        let items = vehicles.map { vehicle in
            VehicleListItem(id: vehicle.id.uuidString, displayName: vehicle.displayName)
        }

        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: vehicleListKey)
        } catch {
            widgetLogger.error("Failed to encode vehicle list: \(error.localizedDescription)")
        }
    }

    /// Remove widget data for a deleted vehicle
    /// - Parameter vehicleID: The UUID string of the deleted vehicle
    func removeWidgetData(for vehicleID: String) {
        guard let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(AppGroupConstants.iPhoneWidget)) in removeWidgetData()")
            return
        }
        userDefaults.removeObject(forKey: widgetDataKey(for: vehicleID))
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Clear all widget data
    func clearWidgetData() {
        guard let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(AppGroupConstants.iPhoneWidget)) in clearWidgetData()")
            return
        }
        userDefaults.removeObject(forKey: widgetDataKey)
        userDefaults.removeObject(forKey: vehicleListKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Pending Widget Completions

    /// Process pending service completions queued by the widget "Done" button
    /// Called when the main app enters foreground
    func processPendingWidgetCompletions(context: ModelContext) {
        let pending = PendingWidgetCompletion.loadAll()
        guard !pending.isEmpty else { return }

        widgetLogger.info("Processing \(pending.count) pending widget completion(s)")

        // Clear immediately to avoid re-processing
        PendingWidgetCompletion.clearAll()

        for completion in pending {
            do {
                // Find vehicle by UUID
                guard let vehicleUUID = UUID(uuidString: completion.vehicleID) else {
                    widgetLogger.error("Invalid vehicle UUID: \(completion.vehicleID)")
                    continue
                }
                let vehicles = try context.fetch(FetchDescriptor<Vehicle>())
                guard let vehicle = vehicles.first(where: { $0.id == vehicleUUID }) else {
                    widgetLogger.error("Vehicle not found for widget completion: \(completion.vehicleID)")
                    continue
                }

                // Find service by UUID
                guard let serviceUUID = UUID(uuidString: completion.serviceID) else {
                    widgetLogger.error("Invalid service UUID: \(completion.serviceID)")
                    continue
                }
                guard let service = (vehicle.services ?? []).first(where: { $0.id == serviceUUID }) else {
                    widgetLogger.error("Service not found for widget completion: \(completion.serviceID)")
                    continue
                }

                // Create service log
                let log = ServiceLog(
                    performedDate: completion.performedDate,
                    mileageAtService: completion.mileageAtService,
                    cost: 0,
                    notes: "Completed via widget"
                )
                log.service = service
                log.vehicle = vehicle
                context.insert(log)

                // Update service tracking
                service.lastPerformed = completion.performedDate
                service.lastMileage = completion.mileageAtService

                // Recalculate next due
                if let intervalMonths = service.intervalMonths, intervalMonths > 0 {
                    service.dueDate = Calendar.current.date(byAdding: .month, value: intervalMonths, to: completion.performedDate)
                } else {
                    service.dueDate = nil
                }
                if let intervalMiles = service.intervalMiles, intervalMiles > 0 {
                    service.dueMileage = completion.mileageAtService + intervalMiles
                } else {
                    service.dueMileage = nil
                }

                // Update vehicle mileage if widget mileage is higher
                if completion.mileageAtService > vehicle.currentMileage {
                    vehicle.currentMileage = completion.mileageAtService
                    vehicle.mileageUpdatedAt = completion.performedDate

                    // Create mileage snapshot
                    let snapshot = MileageSnapshot(
                        mileage: completion.mileageAtService,
                        recordedAt: completion.performedDate,
                        source: .serviceCompletion
                    )
                    snapshot.vehicle = vehicle
                }

                widgetLogger.info("Processed widget completion: \(service.name) for \(vehicle.displayName)")

                // Re-sync widget data
                updateWidget(for: vehicle)
            } catch {
                widgetLogger.error("Failed to process widget completion: \(error.localizedDescription)")
            }
        }

        do {
            try context.save()
        } catch {
            widgetLogger.error("Failed to save widget completions: \(error.localizedDescription)")
        }
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
    let vehicleID: String?
    let vehicleName: String
    let currentMileage: Int
    let estimatedMileage: Int?
    let isEstimatedMileage: Bool
    let services: [SharedService]
    let updatedAt: Date

    struct SharedService: Codable {
        let serviceID: String?      // UUID string of the Service entity (nil for marbete)
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

/// Lightweight vehicle data for widget configuration stored in App Group UserDefaults
struct VehicleListItem: Codable, Sendable {
    let id: String
    let displayName: String
}

/// Pending service completion from widget "Done" button
/// Written by widget extension, read and processed by main app on foreground
struct PendingWidgetCompletion: Codable {
    let serviceID: String
    let vehicleID: String
    let performedDate: Date
    let mileageAtService: Int

    static let userDefaultsKey = "pendingWidgetCompletions"

    static func save(_ completion: PendingWidgetCompletion) {
        guard let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(AppGroupConstants.iPhoneWidget)) in PendingWidgetCompletion.save()")
            return
        }
        var pending = loadAll()
        pending.append(completion)
        if let data = try? JSONEncoder().encode(pending) {
            userDefaults.set(data, forKey: userDefaultsKey)
        }
    }

    static func loadAll() -> [PendingWidgetCompletion] {
        guard let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(AppGroupConstants.iPhoneWidget)) in PendingWidgetCompletion.loadAll()")
            return []
        }
        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([PendingWidgetCompletion].self, from: data)) ?? []
    }

    static func clearAll() {
        guard let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget) else {
            widgetLogger.error("Failed to access App Group UserDefaults (\(AppGroupConstants.iPhoneWidget)) in PendingWidgetCompletion.clearAll()")
            return
        }
        userDefaults.removeObject(forKey: userDefaultsKey)
    }
}

