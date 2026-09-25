//
//  AppState+NotificationRoute.swift
//  checkpoint
//
//  Turns a `NotificationRoute` — where a tapped notification or one of its
//  foreground buttons asked to go — into navigation state. Every route first
//  closes whatever sheet is up, then switches tab, then pushes or presents.
//

import Foundation

extension AppState {

    func apply(_ route: NotificationRoute, vehicles: [Vehicle], now: Date = Date()) {
        // A route for a vehicle deleted since the notification was scheduled
        // has nowhere to go.
        guard let vehicle = vehicles.first(where: { $0.id == route.vehicleID }) else { return }
        selectVehicle(vehicle)

        switch route {
        case .updateMileage:
            showTabRoot(.home)
            present(.mileageUpdate())

        case .costs:
            showTabRoot(.costs)

        case .editVehicle:
            // `present` closes any sheet already up before this one shows.
            present(.editVehicle)

        case .services(_, let serviceIDs):
            let services = Self.services(serviceIDs, in: vehicle)
            if services.count == 1 {
                navigate(to: .service(services[0]), on: .services)
            } else {
                showTabRoot(.services)
            }

        case .markDone(_, let serviceIDs):
            // Services completed or deleted since the reminder was scheduled
            // drop out, so a stale banner can't log one twice. Nothing left:
            // show the services where they stand instead.
            let stillDue = ServiceNotificationScheduler.stillDueServiceIDs(for: vehicle, now: now)
            let services = Self.services(serviceIDs, in: vehicle).filter { stillDue.contains($0.id.uuidString) }
            if services.isEmpty {
                showTabRoot(.services)
            } else {
                present(.markDone(MarkDoneRequest(services: services, vehicle: vehicle)))
            }
        }
    }

    /// Close any sheet, bring `tab` forward, and pop it to its root.
    private func showTabRoot(_ tab: Tab) {
        dismissSheet()
        selectedTab = tab
        paths[tab] = []
    }

    private static func services(_ ids: [UUID], in vehicle: Vehicle) -> [Service] {
        let wanted = Set(ids)
        return (vehicle.services ?? []).filter { wanted.contains($0.id) }
    }
}
