//
//  ClusterNotificationScheduler.swift
//  checkpoint
//
//  Handles scheduling bundled notifications for service clusters
//

import Foundation
import UserNotifications
import os

private let clusterNotificationLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "Notifications.Cluster")

/// Scheduler for cluster notifications - one notification for multiple services
struct ClusterNotificationScheduler {

    // MARK: - Build Notification Requests

    /// Build a notification request for a service cluster
    static func buildClusterNotificationRequest(
        for cluster: ServiceCluster,
        vehicle: Vehicle,
        notificationID: String,
        notificationDate: Date,
        daysBeforeDue: Int = 0
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()

        // Title based on timing
        switch daysBeforeDue {
        case 0:
            content.title = "\(cluster.serviceCount) services due today"
        case 1:
            content.title = "\(cluster.serviceCount) services due tomorrow"
        case 7:
            content.title = "\(cluster.serviceCount) services due this week"
        default:
            content.title = "\(cluster.serviceCount) services due soon"
        }

        // Body: comma-separated service names
        let serviceNames = cluster.services.map { $0.name }.joined(separator: ", ")
        content.body = "\(vehicle.displayName) - \(serviceNames)"

        content.sound = .default
        content.categoryIdentifier = NotificationService.serviceDueCategoryID
        content.userInfo = [
            "type": "cluster",
            "vehicleID": vehicle.id.uuidString,
            "serviceIDs": cluster.services.map { $0.id.uuidString }
        ]

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
    }

    // MARK: - Schedule Cluster Notifications

    /// Schedule notifications for a service cluster at default intervals
    /// - Returns: Base notification ID for tracking
    @discardableResult
    static func scheduleClusterNotification(
        for cluster: ServiceCluster,
        vehicle: Vehicle
    ) -> String? {
        // Use anchor service's effective due date
        guard let dueDate = cluster.anchorService.effectiveDueDate(
            currentMileage: vehicle.currentMileage,
            dailyPace: vehicle.dailyMilesPace
        ), dueDate > Date() else { return nil }

        let baseNotificationID = "cluster-\(UUID().uuidString)"
        let notificationCenter = UNUserNotificationCenter.current()

        // Schedule at default intervals (30, 7, 1, 0 days before)
        for daysBeforeDue in NotificationService.defaultReminderIntervals {
            guard let notificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeDue, to: dueDate),
                  notificationDate > Date() else { continue }

            let notificationID = baseNotificationID + NotificationService.intervalSuffix(for: daysBeforeDue)
            let request = buildClusterNotificationRequest(
                for: cluster,
                vehicle: vehicle,
                notificationID: notificationID,
                notificationDate: notificationDate,
                daysBeforeDue: daysBeforeDue
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    clusterNotificationLogger.error("Failed to schedule cluster notification (\(daysBeforeDue)d before): \(error.localizedDescription)")
                }
            }
        }

        return baseNotificationID
    }

    // MARK: - Cancel Cluster Notifications

    /// Cancel all notifications with a specific base ID
    static func cancelClusterNotification(baseID: String) {
        let allIDs = NotificationService.defaultReminderIntervals.map {
            baseID + NotificationService.intervalSuffix(for: $0)
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIDs)
    }

    /// Cancel all cluster notifications for a vehicle
    static func cancelClusterNotifications(for vehicle: Vehicle) {
        Task {
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()

            let clusterIDs = pending
                .filter { request in
                    guard let type = request.content.userInfo["type"] as? String,
                          type == "cluster",
                          let vehicleID = request.content.userInfo["vehicleID"] as? String else {
                        return false
                    }
                    return vehicleID == vehicle.id.uuidString
                }
                .map { $0.identifier }

            center.removePendingNotificationRequests(withIdentifiers: clusterIDs)
        }
    }

    /// Cancel all cluster notifications
    static func cancelAllClusterNotifications() {
        Task {
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()

            let clusterIDs = pending
                .filter { request in
                    guard let type = request.content.userInfo["type"] as? String else {
                        return false
                    }
                    return type == "cluster"
                }
                .map { $0.identifier }

            center.removePendingNotificationRequests(withIdentifiers: clusterIDs)
        }
    }
}
