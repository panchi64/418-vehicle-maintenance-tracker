//
//  NotificationEntityTags.swift
//  checkpoint
//
//  Tags a reminder banner with the App Entities it is about, so with Apple
//  Intelligence on iOS 27 "mark this done" or "when is it due?" said over
//  the notification reaches the right service or vehicle.
//
//  `UNMutableNotificationContent.appEntityIdentifiers` is iOS 27 (the
//  `_UserNotifications_AppIntents` overlay, which needs both imports below).
//  On iOS 26 tagging does nothing. Snoozes that re-deliver the original
//  content carry its tags along; snoozes that build new content tag it here.
//

import AppIntents
import Foundation
import UserNotifications

enum NotificationEntityTags {

    /// The entities a banner names: each service — as `ServiceEntity`, and on
    /// iOS 27 also as the Reminders schema's `ServiceReminderEntity` — then
    /// the vehicle.
    static func identifiers(serviceIDs: [UUID], appointmentID: UUID? = nil, vehicleID: UUID?) -> [EntityIdentifier] {
        var identifiers = serviceIDs.map { EntityIdentifier(for: ServiceEntity.self, identifier: $0) }
        if #available(iOS 27, *) {
            identifiers += serviceIDs.map { EntityIdentifier(for: ServiceReminderEntity.self, identifier: $0) }
        }
        // A shop-visit reminder names the appointment, and on iOS 27 the
        // same visit as a Calendar event ("move this to Friday").
        if let appointmentID {
            identifiers.append(EntityIdentifier(for: AppointmentEntity.self, identifier: appointmentID))
            if #available(iOS 27, *) {
                identifiers.append(EntityIdentifier(for: AppointmentEventEntity.self, identifier: appointmentID))
            }
        }
        if let vehicleID {
            identifiers.append(EntityIdentifier(for: VehicleEntity.self, identifier: vehicleID))
        }
        return identifiers
    }
}

extension UNMutableNotificationContent {
    func tagEntities(serviceIDs: [UUID] = [], appointmentID: UUID? = nil, vehicleID: UUID?) {
        guard #available(iOS 27, *) else { return }
        appEntityIdentifiers = NotificationEntityTags.identifiers(
            serviceIDs: serviceIDs,
            appointmentID: appointmentID,
            vehicleID: vehicleID
        )
    }
}
