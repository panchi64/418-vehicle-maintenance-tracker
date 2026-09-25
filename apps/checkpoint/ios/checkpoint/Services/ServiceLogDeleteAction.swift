//
//  ServiceLogDeleteAction.swift
//  checkpoint
//
//  The one entry point for deleting a service log from the UI: the model
//  change (`ServiceLogDeletion`), plus the effects that follow it — the
//  notification bundle, app icon, and widget are all computed from the
//  schedules a deletion can move.
//
//  Reversible by default. Where the Undo toast will be visible (the toast
//  renders at the app root, beneath any sheet), the delete happens at once and
//  the toast offers Undo. Where it would not be (inside a sheet), the caller
//  confirms first instead and passes `offerUndo: false` — an Undo nobody can
//  see is not a safety net.
//

import Foundation
import SwiftData

enum ServiceLogDeleteAction {

    static func perform(_ log: ServiceLog, offerUndo: Bool) {
        guard let context = log.modelContext else { return }
        let vehicle = log.vehicle

        let deletion = ServiceLogDeletion.delete(log, in: context)
        HapticService.shared.warning()
        refreshDerivedSurfaces(for: vehicle)

        guard offerUndo else { return }

        ToastService.shared.show(
            L10n.toastServiceLogDeleted,
            icon: "trash",
            style: .info,
            action: ToastService.ToastAction(label: L10n.commonUndo.uppercased()) {
                deletion.undo(in: context)
                refreshDerivedSurfaces(for: vehicle)
                HapticService.shared.selectionChanged()
            }
        )
    }

    private static func refreshDerivedSurfaces(for vehicle: Vehicle?) {
        guard let vehicle else { return }
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
        AppIconService.shared.updateIcon(for: vehicle, services: vehicle.services ?? [])
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}
