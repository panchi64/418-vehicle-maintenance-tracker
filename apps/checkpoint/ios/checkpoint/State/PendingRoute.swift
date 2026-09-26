//
//  PendingRoute.swift
//  checkpoint
//
//  Where something outside the view tree asked the app to go: a tapped
//  notification (or one of its foreground buttons), a widget row, a Siri or
//  Shortcuts intent. Every source stores a route in `PendingRouteStore`; one
//  consumer, `ContentView`, hands it to `AppState.apply` whenever it is on
//  screen — immediately when it already is, or on first appearance after a
//  launch.
//
//  Stored, not posted: the notification delegate used to post a
//  `NotificationCenter` message for the UI, and those lost the race on a cold
//  launch, when iOS delivers the response before any view has subscribed.
//
//  Routes carry IDs, never models or URLs. The app registers no URL scheme
//  (Security Posture, apps/checkpoint/ios/CLAUDE.md); an ID that no longer
//  resolves — deleted since — goes nowhere.
//
//  Out-of-process sources can't reach this store: the widget extension
//  queues `PendingWidgetRoute` in the App Group, and ContentView moves it here.
//

import Foundation

enum PendingRoute: Equatable {
    /// Open the mileage update sheet, from the mileage reminder. (Siri's
    /// Update Mileage records directly and never opens it.)
    case updateMileage(vehicleID: UUID)
    /// Open the Costs tab (yearly roundup, Shortcuts).
    case costs(vehicleID: UUID)
    /// Open the service, or the Services tab for a bundle of several.
    case services(vehicleID: UUID, serviceIDs: [UUID])
    /// Service reminder "Mark as Done": open the completion sheet for the
    /// banner's service, or a visit for all of a bundle's services.
    case markDone(vehicleID: UUID, serviceIDs: [UUID])
    /// Open the vehicle editor, where the marbete lives.
    case editVehicle(vehicleID: UUID)
    /// Switch to the vehicle and show its Home.
    case vehicle(vehicleID: UUID)
    /// Open one service history entry.
    case serviceLog(vehicleID: UUID, logID: UUID)
    /// Open one shop visit.
    case visit(vehicleID: UUID, visitID: UUID)
    /// Open one document, over the vehicle's Documents library.
    case document(vehicleID: UUID, documentID: UUID)
    /// Search the Services tab for `term` (Siri's in-app search).
    case searchServices(vehicleID: UUID, term: String)
    /// Search the vehicle's Documents library for `term`.
    case searchDocuments(vehicleID: UUID, term: String)
    /// Visual Intelligence: open the log form on the receipt it captured
    /// (`VisualCaptureStore`, in memory).
    case logReceipt(vehicleID: UUID, captureID: UUID)
    /// Visual Intelligence: open the mileage sheet with the odometer it read,
    /// in stored miles, for the user to confirm.
    case mileageReading(vehicleID: UUID, reading: Int)
    /// Visual Intelligence: open Add Vehicle with the VIN it read. The
    /// vehicle ID is the one showing; the new vehicle doesn't exist yet.
    case addVehicle(vehicleID: UUID, vin: String)

    /// Open a single service's detail.
    static func service(vehicleID: UUID, serviceID: UUID) -> PendingRoute {
        .services(vehicleID: vehicleID, serviceIDs: [serviceID])
    }

    var vehicleID: UUID {
        switch self {
        case .updateMileage(let id), .costs(let id), .editVehicle(let id), .vehicle(let id):
            return id
        case .services(let id, _), .markDone(let id, _), .serviceLog(let id, _),
             .visit(let id, _), .document(let id, _), .searchServices(let id, _), .searchDocuments(let id, _),
             .logReceipt(let id, _), .mileageReading(let id, _), .addVehicle(let id, _):
            return id
        }
    }

    /// Decode the service IDs a reminder's payload names, dropping malformed ones.
    static func serviceIDs(from strings: [String]) -> [UUID] {
        strings.compactMap(UUID.init(uuidString:))
    }
}

/// The route waiting for `ContentView`. Only the latest request matters: a
/// second tap before the first is consumed replaces it.
@Observable
@MainActor
final class PendingRouteStore {
    static let shared = PendingRouteStore()

    var route: PendingRoute?

    /// Return the waiting route and clear it, so one request navigates once.
    func take() -> PendingRoute? {
        defer { route = nil }
        return route
    }
}
