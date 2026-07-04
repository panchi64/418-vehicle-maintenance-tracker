//
//  ServiceNotificationScheduler+Maintenance.swift
//  checkpoint
//
//  Launch-time cleanup for service due notifications
//

import Foundation
import UserNotifications
import os

private let maintenanceLogger = Logger(category: "Notifications.Maintenance")

extension ServiceNotificationScheduler {

    /// Bring pending service notifications back in line with the data on
    /// this device: sweep orphaned requests, then reschedule every vehicle
    /// so pending content picks up renames, pace changes, and edited dates.
    ///
    /// Orphans accumulate because pending requests are per-device while
    /// `Service.notificationID` syncs through CloudKit — before IDs became
    /// deterministic, a reschedule on another device overwrote the stored ID
    /// and stranded this device's old set, which kept firing with stale
    /// content (e.g. a pre-rename vehicle name) alongside the fresh one.
    static func performLaunchMaintenance(for vehicles: [Vehicle]) async {
        let serviceIDs = vehicles.flatMap { $0.services ?? [] }.map(\.id)
        await removeOrphanedNotifications(validServiceIDs: Set(serviceIDs))
        for vehicle in vehicles {
            await rescheduleNotificationsAwaitingAdds(for: vehicle)
        }
        // Rescheduling every vehicle × service × interval plus marbete/mileage/
        // roundup can exceed the OS's 64-request cap; keep only the soonest.
        // The awaited adds above ensure this trims the settled pending set, not
        // a pre-add snapshot.
        await NotificationHelpers.enforcePendingBudget()
    }

    /// Remove pending service requests whose service no longer exists or
    /// whose identifier predates the deterministic `service-<serviceID>`
    /// scheme — neither can be reached by `cancelAllNotifications(baseID:)`.
    static func removeOrphanedNotifications(validServiceIDs: Set<UUID>) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()

        let orphanedIDs = pending.filter {
            isOrphanedServiceRequest(
                identifier: $0.identifier,
                serviceIDString: $0.content.userInfo["serviceID"] as? String,
                validServiceIDs: validServiceIDs
            )
        }.map(\.identifier)

        guard !orphanedIDs.isEmpty else { return }
        maintenanceLogger.info("Removing \(orphanedIDs.count) orphaned service notification(s)")
        center.removePendingNotificationRequests(withIdentifiers: orphanedIDs)
    }

    /// Whether a pending request no longer maps to a live service's
    /// deterministic notification set. Non-service requests (mileage,
    /// marbete, cluster, roundup) are never considered orphans here.
    static func isOrphanedServiceRequest(
        identifier: String, serviceIDString: String?, validServiceIDs: Set<UUID>
    ) -> Bool {
        guard identifier.hasPrefix("service-") else { return false }
        guard let serviceIDString,
              let serviceID = UUID(uuidString: serviceIDString),
              validServiceIDs.contains(serviceID) else { return true }
        return !identifier.hasPrefix(baseNotificationID(forServiceID: serviceID))
    }
}
