//
//  NotificationRoute.swift
//  checkpoint
//
//  Where a tapped notification (or one of its foreground buttons) should take
//  the user.
//
//  The delegate used to post a `NotificationCenter` message for the UI to
//  act on. Nothing observed most of them, and the ones that were observed
//  lost the race on a cold launch: iOS delivers the response while the app is
//  still starting, before any view has subscribed. A route is *stored*
//  instead (`NotificationService.pendingRoute`) and consumed by `ContentView`
//  whenever it is on screen — immediately when it already is, or on first
//  appearance after a launch.
//

import Foundation

enum NotificationRoute: Equatable {
    /// Mileage reminder: open the mileage update sheet.
    case updateMileage(vehicleID: UUID)
    /// Yearly roundup: open the Costs tab.
    case costs(vehicleID: UUID)
    /// Service reminder tapped: open the service, or the Services tab for a
    /// bundle of several.
    case services(vehicleID: UUID, serviceIDs: [UUID])
    /// Service reminder "Mark as Done": open the completion sheet for the
    /// banner's service, or a visit for all of a bundle's services.
    case markDone(vehicleID: UUID, serviceIDs: [UUID])
    /// Marbete reminder tapped: open the vehicle editor, where the marbete lives.
    case editVehicle(vehicleID: UUID)

    var vehicleID: UUID {
        switch self {
        case .updateMileage(let id), .costs(let id), .editVehicle(let id): return id
        case .services(let id, _), .markDone(let id, _): return id
        }
    }

    /// Decode the service IDs a reminder's payload names, dropping malformed ones.
    static func serviceIDs(from strings: [String]) -> [UUID] {
        strings.compactMap(UUID.init(uuidString:))
    }
}
