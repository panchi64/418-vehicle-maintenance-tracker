//
//  WatchSessionService.swift
//  checkpoint
//
//  iPhone-side WCSession delegate for Apple Watch communication
//  Sends vehicle data to Watch, receives mileage updates and service completions
//

import Foundation
import WatchConnectivity
import SwiftData
import os

private nonisolated enum WatchLog {
    static let logger = Logger(category: "WatchSession")
}

/// A small persisted ring of recently-processed Watch mark-done ids, used to
/// discard duplicate deliveries of the same tap. Persisted (not just in-memory)
/// because a `transferUserInfo` retry can be delivered after the app relaunches.
/// Bounded so it can't grow without limit; the cap comfortably covers the handful
/// of in-flight taps a duplicate could ever race against.
enum WatchMarkDoneDedup {
    static let key = "processedWatchMarkDoneIDs"
    private static let capacity = 25

    static func isDuplicate(_ id: UUID) -> Bool {
        recentIDs().contains(id.uuidString)
    }

    static func record(_ id: UUID) {
        var ids = recentIDs()
        guard !ids.contains(id.uuidString) else { return }
        ids.append(id.uuidString)
        if ids.count > capacity {
            ids.removeFirst(ids.count - capacity)
        }
        UserDefaults.standard.set(ids, forKey: key)
    }

    private static func recentIDs() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
}

@Observable
@MainActor
final class WatchSessionService: NSObject {
    static let shared = WatchSessionService()

    // MARK: - State

    var isWatchReachable = false
    var isWatchAppInstalled = false

    // MARK: - Dependencies

    /// ModelContainer reference for SwiftData access (set during app init)
    var modelContainer: ModelContainer?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Activation

    /// Activate WCSession — call from app init
    func activate() {
        guard WCSession.isSupported() else {
            WatchLog.logger.info("WatchConnectivity not supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        WatchLog.logger.info("WCSession activation requested")
    }

    // MARK: - Send Data to Watch

    /// Send current vehicle data to Apple Watch via application context
    /// Called from WidgetDataService when data changes
    func sendVehicleData(
        vehicleID: String,
        vehicleName: String,
        currentMileage: Int,
        estimatedMileage: Int?,
        isEstimated: Bool,
        services: [WidgetServiceRow],
        distanceUnit: String = "miles"
    ) {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        guard session.activationState == .activated else {
            WatchLog.logger.info("WCSession not activated, skipping Watch update")
            return
        }

        guard session.isPaired && session.isWatchAppInstalled else {
            return
        }

        let watchServices = services.prefix(3).map { service in
            WatchServiceDTO(
                vehicleID: vehicleID,
                serviceID: service.serviceID,
                name: service.name,
                status: mapStatus(service.status),
                dueDescription: service.dueDescription,
                dueMileage: service.dueMileage,
                daysRemaining: service.daysRemaining
            )
        }

        let vehicleData = WatchVehicleDTO(
            vehicleID: vehicleID,
            vehicleName: vehicleName,
            currentMileage: currentMileage,
            estimatedMileage: estimatedMileage,
            isEstimated: isEstimated,
            services: Array(watchServices),
            updatedAt: Date(),
            distanceUnit: distanceUnit
        )

        let context = WatchContextDTO(
            vehicleData: vehicleData,
            lastUpdated: Date()
        )

        do {
            let data = try JSONEncoder().encode(context)
            let contextDict: [String: Any] = ["watchContext": data]
            try session.updateApplicationContext(contextDict)
            WatchLog.logger.info("Sent vehicle data to Watch: \(vehicleName)")
        } catch {
            WatchLog.logger.error("Failed to send data to Watch: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Incoming Messages

    /// Process mileage update from Watch
    private func handleMileageUpdate(_ data: Data) async {
        guard let container = modelContainer else {
            WatchLog.logger.error("No ModelContainer available for mileage update")
            return
        }

        do {
            let update = try JSONDecoder().decode(WatchMileageUpdateDTO.self, from: data)
            let context = ModelContext(container)

            // Find vehicle by ID
            let vehicleID = update.vehicleID
            let predicate = #Predicate<Vehicle> { vehicle in
                vehicle.id.uuidString == vehicleID
            }
            var descriptor = FetchDescriptor<Vehicle>(predicate: predicate)
            descriptor.fetchLimit = 1

            guard let vehicle = try context.fetch(descriptor).first else {
                WatchLog.logger.error("Vehicle not found for mileage update: \(vehicleID)")
                return
            }

            // Update mileage
            vehicle.currentMileage = update.newMileage
            vehicle.mileageUpdatedAt = update.timestamp

            // Create mileage snapshot
            let snapshot = MileageSnapshot(
                mileage: update.newMileage,
                recordedAt: update.timestamp,
                source: .manual
            )
            snapshot.vehicle = vehicle

            try context.save()
            WatchLog.logger.info("Updated mileage from Watch: \(update.newMileage) for \(vehicle.displayName)")

            // Re-sync widget + Watch with updated data
            WidgetDataService.shared.updateWidget(for: vehicle)
        } catch {
            WatchLog.logger.error("Failed to handle mileage update from Watch: \(error.localizedDescription)")
        }
    }

    /// Process mark-service-done from Watch
    private func handleMarkServiceDone(_ data: Data) async {
        guard let container = modelContainer else {
            WatchLog.logger.error("No ModelContainer available for service completion")
            return
        }

        do {
            let completion = try JSONDecoder().decode(WatchMarkServiceDoneDTO.self, from: data)

            // Drop a message we've already logged. `sendMessage` can succeed on
            // the Watch yet have its reply time out, prompting a `transferUserInfo`
            // retry that delivers the same tap twice; without this the phone would
            // write two ServiceLogs for one tap.
            guard !WatchMarkDoneDedup.isDuplicate(completion.id) else {
                WatchLog.logger.info("Ignoring duplicate Watch mark-done delivery: \(completion.id, privacy: .public)")
                return
            }

            let context = ModelContext(container)

            // Find vehicle
            let vehicleID = completion.vehicleID
            let predicate = #Predicate<Vehicle> { vehicle in
                vehicle.id.uuidString == vehicleID
            }
            var descriptor = FetchDescriptor<Vehicle>(predicate: predicate)
            descriptor.fetchLimit = 1

            guard let vehicle = try context.fetch(descriptor).first else {
                WatchLog.logger.error("Vehicle not found for service completion: \(vehicleID)")
                return
            }

            // Find service by UUID (preferred) or fall back to name
            let service: Service? = {
                if let serviceIDString = completion.serviceID,
                   let serviceUUID = UUID(uuidString: serviceIDString) {
                    return (vehicle.services ?? []).first(where: { $0.id == serviceUUID })
                }
                return nil
            }() ?? (vehicle.services ?? []).first(where: { $0.name == completion.serviceName })

            guard let service else {
                WatchLog.logger.error("Service not found: \(completion.serviceID ?? completion.serviceName)")
                return
            }

            // Create service log
            let log = ServiceLog(
                performedDate: completion.performedDate,
                mileageAtService: completion.mileageAtService,
                cost: 0,
                notes: "Completed via Apple Watch"
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

            try context.save()
            // Record the id only after the log is durably saved, so a failed
            // save leaves the tap eligible for a retry delivery.
            WatchMarkDoneDedup.record(completion.id)
            WatchLog.logger.info("Marked service done from Watch: \(completion.serviceName)")

            // Re-sync widget + Watch
            WidgetDataService.shared.updateWidget(for: vehicle)
        } catch {
            WatchLog.logger.error("Failed to handle service completion from Watch: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func mapStatus(_ statusString: String) -> String {
        switch statusString.lowercased() {
        case "overdue": return "overdue"
        case "duesoon": return "dueSoon"
        case "good": return "good"
        default: return "neutral"
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error {
                WatchLog.logger.error("WCSession activation failed: \(error.localizedDescription)")
            } else {
                WatchLog.logger.info("WCSession activated: \(activationState.rawValue)")
                isWatchReachable = session.isReachable
                isWatchAppInstalled = session.isWatchAppInstalled
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        WatchLog.logger.info("WCSession became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WatchLog.logger.info("WCSession deactivated, reactivating...")
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
            WatchLog.logger.info("Watch reachability changed: \(session.isReachable)")
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    /// Handle real-time messages from Watch (when iPhone is reachable)
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            if let data = message[WatchMileageUpdateDTO.messageKey] as? Data {
                await handleMileageUpdate(data)
                replyHandler(["status": "ok"])
            } else if let data = message[WatchMarkServiceDoneDTO.messageKey] as? Data {
                await handleMarkServiceDone(data)
                replyHandler(["status": "ok"])
            } else {
                WatchLog.logger.warning("Unknown message from Watch: \(message.keys.joined(separator: ", "))")
                replyHandler(["status": "unknown"])
            }
        }
    }

    /// Handle queued user info transfers from Watch (offline fallback)
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            if let data = userInfo[WatchMileageUpdateDTO.messageKey] as? Data {
                await handleMileageUpdate(data)
            } else if let data = userInfo[WatchMarkServiceDoneDTO.messageKey] as? Data {
                await handleMarkServiceDone(data)
            } else {
                WatchLog.logger.warning("Unknown userInfo from Watch")
            }
        }
    }
}

// MARK: - DTOs (iPhone-side, matching Watch data format)

/// Vehicle data DTO for encoding to Watch
private struct WatchVehicleDTO: Codable {
    let vehicleID: String
    let vehicleName: String
    let currentMileage: Int
    let estimatedMileage: Int?
    let isEstimated: Bool
    let services: [WatchServiceDTO]
    let updatedAt: Date
    let distanceUnit: String
}

/// Service DTO for encoding to Watch
private struct WatchServiceDTO: Codable {
    let vehicleID: String
    let serviceID: String?
    let name: String
    let status: String
    let dueDescription: String
    let dueMileage: Int?
    let daysRemaining: Int?
}

/// Application context DTO
private struct WatchContextDTO: Codable {
    let vehicleData: WatchVehicleDTO?
    let lastUpdated: Date
}

/// Mileage update DTO from Watch
struct WatchMileageUpdateDTO: Codable {
    let vehicleID: String
    let newMileage: Int
    let timestamp: Date
    static let messageKey = "updateMileage"
}

/// Mark service done DTO from Watch
struct WatchMarkServiceDoneDTO: Codable {
    /// Per-tap identifier used to drop duplicate deliveries (see the dedup ring
    /// in `handleMarkServiceDone`). Decoded defensively: a message from an older
    /// Watch build without an id still processes, just without dedup coverage.
    let id: UUID
    let vehicleID: String
    let serviceID: String?
    let serviceName: String
    let mileageAtService: Int
    let performedDate: Date
    static let messageKey = "markServiceDone"

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        vehicleID = try container.decode(String.self, forKey: .vehicleID)
        serviceID = try container.decodeIfPresent(String.self, forKey: .serviceID)
        serviceName = try container.decode(String.self, forKey: .serviceName)
        mileageAtService = try container.decode(Int.self, forKey: .mileageAtService)
        performedDate = try container.decode(Date.self, forKey: .performedDate)
    }
}
