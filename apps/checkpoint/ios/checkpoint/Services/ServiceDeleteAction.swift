//
//  ServiceDeleteAction.swift
//  checkpoint
//
//  The UI entry points for removing a service from the schedule, plus the
//  effects that follow — reminders, app icon and widget are all computed from
//  the schedules these change. The sibling of `ServiceLogDeleteAction`.
//
//  Deleting a service cascades to its history, so it is confirmed by the
//  caller and not undoable. Stopping tracking writes nothing but the schedule,
//  so it happens at once and offers Undo.
//

import Foundation
import SwiftData

enum ServiceDeleteAction {

    /// Deletes services (and, by cascade, their logs). Callers confirm first.
    static func delete(_ services: [Service], vehicle: Vehicle, in context: ModelContext) {
        guard !services.isEmpty else { return }
        for service in services {
            AnalyticsService.shared.capture(.serviceDeleted)
            context.delete(service)
        }
        // Cascaded logs nullify their attachments; sweep any left with neither
        // a log nor a vehicle so they don't linger in storage with no owner.
        Document.purgeOrphans(in: context)
        HapticService.shared.warning()
        refreshDerivedSurfaces(for: vehicle)
    }

    /// Takes a service off the schedule without writing a log, with Undo.
    static func stopTracking(_ service: Service, vehicle: Vehicle) {
        let snapshot = service.stopTracking()
        HapticService.shared.selectionChanged()
        refreshDerivedSurfaces(for: vehicle)

        ToastService.shared.show(
            L10n.servicesToastStoppedTracking(service.name),
            icon: "bell.slash",
            style: .info,
            action: ToastService.ToastAction(label: L10n.commonUndo.uppercased()) {
                service.restoreTracking(snapshot)
                refreshDerivedSurfaces(for: vehicle)
                HapticService.shared.selectionChanged()
            }
        )
    }

    static func refreshDerivedSurfaces(for vehicle: Vehicle) {
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
        AppIconService.shared.updateIcon(for: vehicle, services: vehicle.services ?? [])
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}
