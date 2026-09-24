//
//  AppState+NotificationRoute.swift
//  checkpoint
//
//  Turns a `NotificationRoute` — where a tapped notification or one of its
//  foreground buttons asked to go — into navigation state.
//

import Foundation

extension AppState {

    func apply(_ route: NotificationRoute, vehicles: [Vehicle], now: Date = Date()) {
        // A route for a vehicle deleted since the notification was scheduled
        // has nowhere to go.
        guard let vehicle = vehicles.first(where: { $0.id == route.vehicleID }) else { return }
        if selectedVehicle?.id != vehicle.id {
            selectedVehicle = vehicle
        }

        switch route {
        case .updateMileage:
            selectedTab = .home
            showMileageUpdate = true

        case .costs:
            selectedTab = .costs

        case .editVehicle:
            showEditVehicle = true

        case .services(_, let serviceIDs):
            let services = Self.services(serviceIDs, in: vehicle)
            if services.count == 1 {
                selectedService = services[0]
            } else {
                selectedTab = .services
            }

        case .markDone(_, let serviceIDs):
            // Services completed or deleted since the reminder was scheduled
            // drop out, so a stale banner can't log one twice. Nothing left:
            // show the services where they stand instead.
            let stillDue = ServiceNotificationScheduler.stillDueServiceIDs(for: vehicle, now: now)
            let services = Self.services(serviceIDs, in: vehicle).filter { stillDue.contains($0.id.uuidString) }
            if services.isEmpty {
                selectedTab = .services
            } else {
                markDoneRequest = MarkDoneRequest(services: services, vehicle: vehicle)
            }
        }
    }

    private static func services(_ ids: [UUID], in vehicle: Vehicle) -> [Service] {
        let wanted = Set(ids)
        return (vehicle.services ?? []).filter { wanted.contains($0.id) }
    }
}
