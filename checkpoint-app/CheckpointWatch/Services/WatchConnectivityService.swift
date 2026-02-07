//
//  WatchConnectivityService.swift
//  CheckpointWatch
//
//  Watch-side WCSession delegate — receives data from iPhone, sends actions back
//  Persists received data to watch App Group for complications access
//

import Foundation
import WatchConnectivity
import WidgetKit
import os

private let watchLogger = Logger(subsystem: "com.418-studio.checkpoint.watch", category: "Connectivity")

@Observable
@MainActor
final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    // MARK: - State

    var isPhoneReachable = false
    var lastSyncError: String?

    // MARK: - Dependencies

    private let dataStore = WatchDataStore.shared

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Activation

    func activate() {
        guard WCSession.isSupported() else {
            watchLogger.info("WCSession not supported")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        watchLogger.info("Watch WCSession activation requested")
    }

    // MARK: - Send to iPhone

    /// Send mileage update to iPhone
    func sendMileageUpdate(vehicleID: String, newMileage: Int) {
        let update = WatchMileageUpdate(
            vehicleID: vehicleID,
            newMileage: newMileage,
            timestamp: Date()
        )

        guard let data = try? JSONEncoder().encode(update) else {
            watchLogger.error("Failed to encode mileage update")
            return
        }

        let message: [String: Any] = [WatchMileageUpdate.messageKey: data]
        sendToPhone(message: message, key: WatchMileageUpdate.messageKey, data: data)

        // Optimistic local update
        dataStore.updateMileageOptimistically(newMileage)
    }

    /// Send mark-service-done to iPhone
    func sendMarkServiceDone(vehicleID: String, serviceName: String, mileageAtService: Int) {
        let completion = WatchMarkServiceDone(
            vehicleID: vehicleID,
            serviceName: serviceName,
            mileageAtService: mileageAtService,
            performedDate: Date()
        )

        guard let data = try? JSONEncoder().encode(completion) else {
            watchLogger.error("Failed to encode service completion")
            return
        }

        let message: [String: Any] = [WatchMarkServiceDone.messageKey: data]
        sendToPhone(message: message, key: WatchMarkServiceDone.messageKey, data: data)

        // Optimistic local update
        dataStore.markServiceDoneOptimistically(serviceName)
    }

    // MARK: - Private Helpers

    /// Send message with fallback to transferUserInfo for offline delivery
    private func sendToPhone(message: [String: Any], key: String, data: Data) {
        let session = WCSession.default

        if session.isReachable {
            session.sendMessage(message, replyHandler: { reply in
                watchLogger.info("iPhone acknowledged \(key): \(reply)")
            }, errorHandler: { error in
                watchLogger.error("sendMessage failed for \(key): \(error.localizedDescription)")
                // Fallback to queued transfer
                session.transferUserInfo(message)
                watchLogger.info("Queued \(key) via transferUserInfo")
            })
        } else {
            // Phone not reachable — queue for later delivery
            session.transferUserInfo(message)
            watchLogger.info("Phone not reachable, queued \(key) via transferUserInfo")
            lastSyncError = "WILL SYNC WHEN PHONE IS NEARBY"
        }
    }

    // MARK: - Process Incoming Data

    private func processApplicationContext(_ context: [String: Any]) {
        guard let data = context["watchContext"] as? Data else {
            watchLogger.warning("No watchContext in application context")
            return
        }

        do {
            let watchContext = try JSONDecoder().decode(WatchApplicationContext.self, from: data)
            if let vehicleData = watchContext.vehicleData {
                dataStore.save(vehicleData)
                watchLogger.info("Received vehicle data: \(vehicleData.vehicleName)")

                // Reload Watch complications
                WidgetCenter.shared.reloadAllTimelines()
            }
            lastSyncError = nil
        } catch {
            watchLogger.error("Failed to decode application context: \(error.localizedDescription)")
            lastSyncError = "SYNC ERROR"
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error {
                watchLogger.error("Watch WCSession activation failed: \(error.localizedDescription)")
                lastSyncError = "CONNECTION ERROR"
            } else {
                watchLogger.info("Watch WCSession activated: \(activationState.rawValue)")
                isPhoneReachable = session.isReachable

                // Process any pending application context
                if !session.receivedApplicationContext.isEmpty {
                    processApplicationContext(session.receivedApplicationContext)
                }
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isPhoneReachable = session.isReachable
            watchLogger.info("Phone reachability changed: \(session.isReachable)")
            if session.isReachable {
                lastSyncError = nil
            }
        }
    }

    /// Receive updated application context from iPhone
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            processApplicationContext(applicationContext)
        }
    }

    /// Receive real-time message from iPhone (e.g., confirmation after Watch action)
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            // iPhone may send updated context after processing a Watch action
            if message["watchContext"] != nil {
                processApplicationContext(message)
            }
        }
    }
}
