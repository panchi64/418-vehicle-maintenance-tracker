//
//  EntityRoutes.swift
//  checkpoint
//
//  Where opening an entity lands: the `PendingRoute` for a vehicle, service,
//  service log, visit or document ID. Every open intent — the iOS 27
//  `.system.open` / `.files.openFile` schemas and in-app search — resolves
//  through here, so each kind of record opens on the same screen whichever
//  entity type named it.
//

import Foundation
import SwiftData

@MainActor
enum EntityRoutes {

    static func vehicle(_ id: UUID, in context: ModelContext) throws -> PendingRoute {
        .vehicle(vehicleID: try IntentStore.vehicle(id: id, in: context).id)
    }

    static func service(_ id: UUID, in context: ModelContext) throws -> PendingRoute {
        let service = try IntentStore.service(id: id, in: context)
        return .service(vehicleID: try IntentStore.vehicle(of: service).id, serviceID: service.id)
    }

    static func serviceLog(_ id: UUID, in context: ModelContext) throws -> PendingRoute {
        guard let log = try ServiceLogEntity.models(ids: [id], in: context).first,
              let vehicle = log.vehicle else { throw IntentError.serviceLogNotFound }
        return .serviceLog(vehicleID: vehicle.id, logID: log.id)
    }

    static func visit(_ id: UUID, in context: ModelContext) throws -> PendingRoute {
        guard let visit = try VisitEntity.models(ids: [id], in: context).first,
              let vehicle = visit.vehicle else { throw IntentError.visitNotFound }
        return .visit(vehicleID: vehicle.id, visitID: visit.id)
    }

    /// A document opens over the library of a vehicle it is linked to —
    /// the selected one when it is linked to several.
    static func document(
        _ id: UUID,
        in context: ModelContext,
        defaults: UserDefaults = .standard
    ) throws -> PendingRoute {
        let document = try IntentStore.document(id: id, in: context)
        let vehicles = document.vehicles ?? []
        let selectedID = defaults.string(forKey: AppGroupConstants.appSelectedVehicleIDKey)
        guard let vehicle = vehicles.first(where: { $0.id.uuidString == selectedID }) ?? vehicles.first else {
            throw IntentError.documentNotFound
        }
        return .document(vehicleID: vehicle.id, documentID: document.id)
    }

    /// Hand `route` to the app. `ContentView` applies it once it is on screen.
    static func open(_ route: PendingRoute) {
        PendingRouteStore.shared.route = route
    }
}
