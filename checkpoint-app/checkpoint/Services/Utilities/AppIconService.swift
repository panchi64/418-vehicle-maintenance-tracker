//
//  AppIconService.swift
//  checkpoint
//
//  Manages dynamic app icon switching based on service status
//

import UIKit
import SwiftData
import os

private let appIconLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "AppIcon")

@MainActor
final class AppIconService {
    static let shared = AppIconService()

    private init() {}

    /// Icon names matching Info.plist CFBundleAlternateIcons
    enum AppIconName: String {
        case advisory = "AppIcon-Advisory"
        case critical = "AppIcon-Critical"
    }

    /// Updates the app icon based on the most urgent service status.
    /// Respects the user's auto-change preference in `AppIconSettings`.
    /// - Parameters:
    ///   - vehicle: The currently selected vehicle
    ///   - services: All services to evaluate
    func updateIcon(for vehicle: Vehicle?, services: [Service]) {
        guard UIApplication.shared.supportsAlternateIcons else {
            appIconLogger.info("Alternate icons not supported")
            return
        }

        // When auto-change is disabled, always revert to the default icon
        guard AppIconSettings.shared.autoChangeEnabled else {
            appIconLogger.debug("Auto-change disabled")
            resetToDefaultIcon()
            return
        }

        let targetIconName = determineIconName(for: vehicle, services: services)
        let currentIconName = UIApplication.shared.alternateIconName

        appIconLogger.debug("Current: \(currentIconName ?? "default", privacy: .public), Target: \(targetIconName ?? "default", privacy: .public)")

        // Only update if the icon needs to change
        guard targetIconName != currentIconName else {
            appIconLogger.debug("No change needed")
            return
        }

        UIApplication.shared.setAlternateIconName(targetIconName) { error in
            if let error = error {
                appIconLogger.error("Failed to update: \(error.localizedDescription)")
            } else {
                appIconLogger.info("Successfully changed to: \(targetIconName ?? "default", privacy: .public)")
            }
        }
    }

    /// Determines which icon to display based on service status
    private func determineIconName(for vehicle: Vehicle?, services: [Service]) -> String? {
        guard let vehicle = vehicle else {
            appIconLogger.debug("No vehicle selected")
            return nil
        }

        // Filter services for this vehicle and find the most urgent
        let vehicleServices = services.filter { $0.vehicle?.id == vehicle.id }

        guard let mostUrgentService = vehicleServices
            .sorted(by: { $0.urgencyScore(currentMileage: vehicle.currentMileage) < $1.urgencyScore(currentMileage: vehicle.currentMileage) })
            .first
        else {
            appIconLogger.debug("No services for vehicle")
            return nil
        }

        // Determine icon based on status
        let status = mostUrgentService.status(currentMileage: vehicle.currentMileage)
        appIconLogger.debug("Most urgent service: \(mostUrgentService.name, privacy: .public), status: \(String(describing: status), privacy: .public)")

        switch status {
        case .overdue:
            return AppIconName.critical.rawValue
        case .dueSoon:
            return AppIconName.advisory.rawValue
        case .good, .neutral:
            return nil // Default (nominal) icon
        }
    }

    /// Resets the app icon to the default if an alternate is currently set
    func resetToDefaultIcon() {
        guard UIApplication.shared.alternateIconName != nil else { return }

        UIApplication.shared.setAlternateIconName(nil) { error in
            if let error = error {
                appIconLogger.error("Failed to reset: \(error.localizedDescription)")
            } else {
                appIconLogger.info("Reset to default icon")
            }
        }
    }
}
