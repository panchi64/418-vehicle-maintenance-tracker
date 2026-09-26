//
//  DerivedSurfaces.swift
//  checkpoint
//
//  Everything outside the store that is computed from a vehicle's schedules:
//  the reminder notifications, the app icon's status badge and the widget.
//  After a write that can move what is due, refresh them together so no
//  surface quotes a schedule the others have moved past.
//
//  Shared by the delete actions and the App Intents that write. Views that
//  save through a form keep their own refresh, because they also own a toast
//  and an undo that must follow the same change.
//

import Foundation

enum DerivedSurfaces {

    static func refresh(for vehicle: Vehicle) {
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
        // The icon mirrors the selected vehicle only; a change to another one
        // must not repaint it with that vehicle's status.
        if isSelected(vehicle) {
            AppIconService.shared.updateIcon(for: vehicle, services: vehicle.services ?? [])
        }
        WidgetDataService.shared.updateWidget(for: vehicle)
    }

    /// Whether `vehicle` is the one the app shows. With no selection persisted
    /// yet (a fresh install), any vehicle is.
    static func isSelected(_ vehicle: Vehicle, defaults: UserDefaults = .standard) -> Bool {
        guard let selected = defaults.string(forKey: AppGroupConstants.appSelectedVehicleIDKey) else { return true }
        return selected == vehicle.id.uuidString
    }
}
