//
//  AppIconService.swift
//  checkpoint
//
//  Manages dynamic app icon switching based on service status
//

import UIKit
import SwiftData

@MainActor
final class AppIconService {
    static let shared = AppIconService()

    private init() {}

    /// Icon names matching Info.plist CFBundleAlternateIcons
    enum AppIconName: String {
        case advisory = "AppIcon-Advisory"
        case critical = "AppIcon-Critical"
    }

    /// Updates the app icon based on the most urgent service status
    /// - Parameters:
    ///   - vehicle: The currently selected vehicle
    ///   - services: All services to evaluate
    func updateIcon(for vehicle: Vehicle?, services: [Service]) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("[AppIcon] Alternate icons not supported")
            return
        }

        let targetIconName = determineIconName(for: vehicle, services: services)
        let currentIconName = UIApplication.shared.alternateIconName

        print("[AppIcon] Current: \(currentIconName ?? "default"), Target: \(targetIconName ?? "default")")

        // Only update if the icon needs to change
        guard targetIconName != currentIconName else {
            print("[AppIcon] No change needed")
            return
        }

        UIApplication.shared.setAlternateIconName(targetIconName) { error in
            if let error = error {
                print("[AppIcon] Failed to update: \(error.localizedDescription)")
            } else {
                print("[AppIcon] Successfully changed to: \(targetIconName ?? "default")")
            }
        }
    }

    /// Determines which icon to display based on service status
    private func determineIconName(for vehicle: Vehicle?, services: [Service]) -> String? {
        guard let vehicle = vehicle else {
            print("[AppIcon] No vehicle selected")
            return nil
        }

        // Filter services for this vehicle and find the most urgent
        let vehicleServices = services.filter { $0.vehicle?.id == vehicle.id }

        guard let mostUrgentService = vehicleServices
            .sorted(by: { $0.urgencyScore(currentMileage: vehicle.currentMileage) < $1.urgencyScore(currentMileage: vehicle.currentMileage) })
            .first
        else {
            print("[AppIcon] No services for vehicle")
            return nil
        }

        // Determine icon based on status
        let status = mostUrgentService.status(currentMileage: vehicle.currentMileage)
        print("[AppIcon] Most urgent service: \(mostUrgentService.name), status: \(status)")

        switch status {
        case .overdue:
            return AppIconName.critical.rawValue
        case .dueSoon:
            return AppIconName.advisory.rawValue
        case .good, .neutral:
            return nil // Default (nominal) icon
        }
    }
}
