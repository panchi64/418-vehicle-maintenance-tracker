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

private let widgetLogger = Logger(category: "Widget")

/// Service for updating widget data in the shared App Group container
@MainActor
final class WidgetDataService {
    static let shared = WidgetDataService()

    private let widgetDataKey = AppGroupConstants.widgetDataKey
    private let vehicleListKey = AppGroupConstants.vehicleListKey
    private let appSelectedVehicleIDKey = AppGroupConstants.appSelectedVehicleIDKey

    private var widgetDefaults: UserDefaults? {
        AppGroupConstants.iPhoneWidgetDefaults()
    }

    /// ModelContainer used to re-serialize snapshots when CloudKit reports a
    /// remote change. Set during app init (see `checkpointApp`). Nil in contexts
    /// that never wire it (e.g. tests), where remote-change handling degrades to
    /// a plain timeline reload.
    var modelContainer: ModelContainer?

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

    /// Handle remote changes by re-serializing snapshots, then reloading widgets.
    ///
    /// A bare `reloadAllTimelines()` would make the widget re-decode the *same*
    /// stale JSON another device just superseded. Re-serialize every vehicle's
    /// snapshot from the model container first so the reload reflects the synced
    /// state. Falls back to a plain reload when no container is wired.
    private func handleRemoteChange() {
        // Prefer our own wired container; fall back to the one WatchSessionService
        // already holds so this works even before `modelContainer` is set.
        guard let container = modelContainer ?? WatchSessionService.shared.modelContainer else {
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        let context = ModelContext(container)
        let vehicles: [Vehicle]
        do {
            vehicles = try context.fetch(FetchDescriptor<Vehicle>())
        } catch {
            widgetLogger.error("Failed to fetch vehicles on remote change: \(error.localizedDescription)")
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        for vehicle in vehicles {
            let input = snapshotInput(for: vehicle)
            writeSnapshot(
                vehicleID: vehicle.id.uuidString,
                vehicleName: input.vehicleName,
                currentMileage: input.currentMileage,
                estimatedMileage: input.estimatedMileage,
                isEstimated: input.isEstimated,
                services: input.services
            )
        }
        updateVehicleList(vehicles)

        // One reload after all snapshots are rewritten (avoids N reloads).
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Returns the vehicle-specific widget data key
    private func widgetDataKey(for vehicleID: String) -> String {
        "\(AppGroupConstants.widgetDataKeyPrefix)\(vehicleID)"
    }

    /// Whether `vehicleID` is the vehicle the app currently has selected, i.e.
    /// the one the "Match App" widget should mirror. When no selection is
    /// persisted yet (fresh launch) we treat any vehicle as a match so the shared
    /// key stays populated rather than leaving the widget blank.
    private func isSelectedVehicle(_ vehicleID: String) -> Bool {
        guard let selected = widgetDefaults?.string(forKey: appSelectedVehicleIDKey) else {
            return true
        }
        return selected == vehicleID
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
        services: [WidgetServiceRow]
    ) {
        writeSnapshot(
            vehicleID: vehicleID,
            vehicleName: vehicleName,
            currentMileage: currentMileage,
            estimatedMileage: estimatedMileage,
            isEstimated: isEstimated,
            services: services
        )

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()

        // Send to Apple Watch (include distance unit preference)
        WatchSessionService.shared.sendVehicleData(
            vehicleID: vehicleID,
            vehicleName: vehicleName,
            currentMileage: currentMileage,
            estimatedMileage: estimatedMileage,
            isEstimated: isEstimated,
            services: services,
            distanceUnit: DistanceSettings.shared.unit.rawValue
        )
    }

    /// Serialize one vehicle's snapshot into the App Group without reloading
    /// timelines or messaging the Watch — the shared write path used both by the
    /// single-vehicle `updateWidgetData` and the bulk re-serialize on remote
    /// change. Always writes the per-vehicle key; writes the shared "match app"
    /// key only when this vehicle is the app's current selection, so editing a
    /// background vehicle can't repoint the Match-App widget onto it.
    private func writeSnapshot(
        vehicleID: String,
        vehicleName: String,
        currentMileage: Int,
        estimatedMileage: Int?,
        isEstimated: Bool,
        services: [WidgetServiceRow]
    ) {
        guard let userDefaults = widgetDefaults else {
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
                daysRemaining: service.daysRemaining,
                duePeriod: service.duePeriod,
                dueDate: service.dueDate
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
            // Store with vehicle-specific key (used by explicitly-configured widgets).
            userDefaults.set(data, forKey: widgetDataKey(for: vehicleID))
            // Mirror into the shared "match app" key only for the selected vehicle.
            if isSelectedVehicle(vehicleID) {
                userDefaults.set(data, forKey: widgetDataKey)
            }
        } catch {
            widgetLogger.error("Failed to encode widget data: \(error.localizedDescription)")
        }
    }

    /// Update widget from a Vehicle and its services (including marbete if configured)
    func updateWidget(for vehicle: Vehicle) {
        let input = snapshotInput(for: vehicle)
        updateWidgetData(
            vehicleID: vehicle.id.uuidString,
            vehicleName: input.vehicleName,
            currentMileage: input.currentMileage,
            estimatedMileage: input.estimatedMileage,
            isEstimated: input.isEstimated,
            services: input.services
        )
    }

    /// Build the widget/watch snapshot rows for a vehicle: its due-tracked
    /// services plus the marbete row, sorted by urgency. Each row carries the raw
    /// `dueDate` so the widget can recompute the countdown per timeline entry.
    private func snapshotInput(for vehicle: Vehicle) -> (vehicleName: String, currentMileage: Int, estimatedMileage: Int?, isEstimated: Bool, services: [WidgetServiceRow]) {
        let effectiveMileage = vehicle.effectiveMileage
        let pace = vehicle.dailyMilesPace

        // Create service items (only services with due tracking)
        var allItems: [(row: WidgetServiceRow, urgencyScore: Int)] = (vehicle.services ?? [])
            .filter { $0.hasDueTracking }
            .map { service in
            let status = service.status(currentMileage: effectiveMileage)

            // Project the due date (considering pace) once, then derive both the
            // day count and the abstracted period from that same date so every
            // surface stays consistent with the Next Up card.
            let effectiveDue = service.effectiveDueDate(currentMileage: effectiveMileage, dailyPace: pace)
            let daysRemaining = effectiveDue.map {
                Calendar.current.dateComponents([.day], from: .now, to: $0).day ?? 0
            }

            let row: WidgetServiceRow = (
                serviceID: service.id.uuidString,
                name: service.name,
                status: statusString(for: status),
                dueDescription: serviceDueDescription(for: service, effectiveDue: effectiveDue),
                dueMileage: service.dueMileage,
                daysRemaining: daysRemaining,
                duePeriod: Self.duePeriod(for: effectiveDue),
                dueDate: effectiveDue
            )
            return (row: row, urgencyScore: service.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace))
        }

        // Add marbete if configured
        if vehicle.hasMarbeteExpiration {
            let marbeteStatus = vehicle.marbeteStatus
            let expiration = vehicle.marbeteExpirationDate

            let dueDescription: String
            if let expiration {
                dueDescription = Self.periodPhrase(
                    DuePeriodFormatter.describe(expiration),
                    phraseFormat: String(localized: "Expires %@"),
                    overdueWord: String(localized: "Expired")
                )
            } else {
                dueDescription = vehicle.marbeteExpirationFormatted ?? "Set"
            }

            let row: WidgetServiceRow = (
                serviceID: nil,
                name: "Marbete Renewal",
                status: statusString(for: marbeteStatus),
                dueDescription: dueDescription,
                dueMileage: nil,  // Marbete has no mileage component
                daysRemaining: vehicle.daysUntilMarbeteExpiration,
                duePeriod: Self.duePeriod(for: expiration),
                dueDate: expiration
            )
            allItems.append((row: row, urgencyScore: vehicle.marbeteUrgencyScore))
        }

        // Sort all items by urgency score, then drop the score.
        let serviceData = allItems.sorted { $0.urgencyScore < $1.urgencyScore }.map { $0.row }

        return (
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
        guard let userDefaults = widgetDefaults else {
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
        guard let userDefaults = widgetDefaults else {
            widgetLogger.error("Failed to access App Group UserDefaults in removeWidgetData()")
            return
        }
        userDefaults.removeObject(forKey: widgetDataKey(for: vehicleID))
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Clear all widget data
    func clearWidgetData() {
        guard let userDefaults = widgetDefaults else {
            widgetLogger.error("Failed to access App Group UserDefaults in clearWidgetData()")
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

                // Close this occurrence and (if recurring) spawn the next.
                ServiceCompletionService.completeService(
                    service,
                    performedDate: completion.performedDate,
                    mileage: completion.mileageAtService,
                    in: context
                )

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
            // Clear only after the logs are durably saved; a failed save leaves
            // the queue so the completions are reprocessed next foreground rather
            // than silently lost. Completions dedupe on serviceID, so a reprocess
            // after partial work stays safe.
            PendingWidgetCompletion.clearAll()
        } catch {
            widgetLogger.error("Failed to save widget completions: \(error.localizedDescription). Leaving queue intact for retry.")
        }
    }

    /// Abstracted month period for the widget hero ("Mid May" / "This week" /
    /// "Overdue"), computed from the actual due date so it matches the Next Up
    /// card exactly (reconstructing from a truncated day count could land a day
    /// early and flip the month bucket near a boundary).
    nonisolated static func duePeriod(for dueDate: Date?) -> String? {
        guard let dueDate else { return nil }
        return DuePeriodFormatter.describe(dueDate).label
    }

    /// "verb + period" phrasing for date-based due text, e.g. "Due mid May" /
    /// "Overdue", or "Expires mid May" / "Expired" for marbete. `phraseFormat`
    /// is a localized format string with a single `%@` for the period, so word
    /// order follows the locale (Spanish: "Vence a mediados de may").
    nonisolated static func periodPhrase(_ period: DuePeriodFormatter.Period, phraseFormat: String, overdueWord: String) -> String {
        period.phrased(format: phraseFormat, overdueWord: overdueWord)
    }

    /// Due text for the shared payload: mileage phrasing for mileage-tracked
    /// services, otherwise an abstracted month period ("Due mid May" / "Overdue")
    /// so widget, watch, and Siri read consistently with the Next Up card.
    private func serviceDueDescription(for service: Service, effectiveDue: Date?) -> String {
        if service.dueMileage != nil {
            return service.primaryDescription ?? "Scheduled"
        }
        guard let due = effectiveDue else {
            return service.primaryDescription ?? "Scheduled"
        }
        return Self.periodPhrase(
            DuePeriodFormatter.describe(due),
            phraseFormat: String(localized: "Due %@"),
            overdueWord: String(localized: "Overdue")
        )
    }

    private func statusString(for status: ServiceStatus) -> String {
        switch status {
        case .overdue: return "overdue"
        case .dueSoon: return "dueSoon"
        case .good: return "good"
        case .neutral: return "neutral"
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

/// One service/marbete row destined for the widget + watch snapshot. Carries
/// both the precomputed display fields and the raw `dueDate` so the widget can
/// recompute the countdown against each timeline entry's date.
typealias WidgetServiceRow = (
    serviceID: String?,
    name: String,
    status: String,
    dueDescription: String,
    dueMileage: Int?,
    daysRemaining: Int?,
    duePeriod: String?,
    dueDate: Date?
)

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
        let duePeriod: String?      // Abstracted month period for date-based hero (e.g. "Mid May")
        let dueDate: Date?          // Raw due date; lets the widget recompute the countdown over time
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

// PendingWidgetCompletion is defined in CheckpointWidget/Shared/ and compiled
// into both the widget and app targets (see the SharedEntities group).

