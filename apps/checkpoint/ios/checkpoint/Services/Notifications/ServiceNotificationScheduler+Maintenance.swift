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

    /// Remove pending service requests that no longer match live data — a
    /// service that was deleted, or a bundle naming one.
    static func removeOrphanedNotifications(validServiceIDs: Set<UUID>) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()

        let orphanedIDs = pending.filter {
            isOrphanedServiceRequest(
                identifier: $0.identifier,
                userInfo: $0.content.userInfo,
                validServiceIDs: validServiceIDs
            )
        }.map(\.identifier)

        guard !orphanedIDs.isEmpty else { return }
        maintenanceLogger.info("Removing \(orphanedIDs.count) orphaned service notification(s)")
        center.removePendingNotificationRequests(withIdentifiers: orphanedIDs)
    }

    /// Whether a pending request no longer maps to live services. Non-service
    /// requests (mileage, marbete, roundup) are never considered orphans here.
    ///
    /// A bundle is orphaned if *any* service it names is gone: its body lists
    /// that service, so the content is wrong even though the rest of the set
    /// still exists. The reschedule that follows this sweep re-adds a correct
    /// bundle for whatever remains.
    static func isOrphanedServiceRequest(
        identifier: String, userInfo: [AnyHashable: Any], validServiceIDs: Set<UUID>
    ) -> Bool {
        guard identifier.hasPrefix(requestPrefix) else { return false }

        let referenced = referencedServiceIDs(in: userInfo)
        // A service request that names no service can't be verified, and
        // nothing that still schedules is capable of producing one.
        guard !referenced.isEmpty else { return true }

        return referenced.contains { idString in
            guard let id = UUID(uuidString: idString) else { return true }
            return !validServiceIDs.contains(id)
        }
    }
}
