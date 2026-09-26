//
//  IntentStore.swift
//  checkpoint
//
//  How an intent turns the entities Siri resolved back into models, and how
//  it finishes a write. Every intent resolves and commits through here, so a
//  write from Siri leaves the app exactly where the same edit made in-app
//  would: saved, reminders rebuilt, icon and widget current, Spotlight
//  following.
//

import AppIntents
import SwiftData

/// What an intent says when it can't go on. Spoken, so each case names the
/// next step rather than the failure.
nonisolated enum IntentError: Error, Equatable, CustomLocalizedStringResourceConvertible {
    case noVehicles
    case vehicleNotFound
    case serviceNotFound
    case serviceLogNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noVehicles: "Add a vehicle in Checkpoint first."
        case .vehicleNotFound: "That vehicle is no longer in Checkpoint."
        case .serviceNotFound: "That service is no longer in Checkpoint."
        case .serviceLogNotFound: "That service log is no longer in Checkpoint."
        }
    }
}

@MainActor
enum IntentStore {

    /// The vehicle `entity` names, or — when the phrase named none — the one
    /// the app has selected, so "update mileage" means the car on screen.
    /// Falls back to the first vehicle before any selection is persisted.
    static func vehicle(
        for entity: VehicleEntity?,
        in context: ModelContext,
        defaults: UserDefaults = .standard
    ) throws -> Vehicle {
        if let entity {
            guard let vehicle = try VehicleEntity.models(ids: [entity.id], in: context).first else {
                throw IntentError.vehicleNotFound
            }
            return vehicle
        }
        let vehicles = try VehicleEntity.models(ids: nil, in: context)
        guard !vehicles.isEmpty else { throw IntentError.noVehicles }
        let selectedID = defaults.string(forKey: AppGroupConstants.appSelectedVehicleIDKey)
        return vehicles.first { $0.id.uuidString == selectedID } ?? vehicles[0]
    }

    static func service(_ entity: ServiceEntity, in context: ModelContext) throws -> Service {
        guard let service = try ServiceEntity.models(ids: [entity.id], in: context).first else {
            throw IntentError.serviceNotFound
        }
        return service
    }

    static func services(_ entities: [ServiceEntity], in context: ModelContext) throws -> [Service] {
        let services = try ServiceEntity.models(ids: entities.map(\.id), in: context)
        guard !services.isEmpty || entities.isEmpty else { throw IntentError.serviceNotFound }
        return services
    }

    static func logs(_ entities: [ServiceLogEntity], in context: ModelContext) throws -> [ServiceLog] {
        let logs = try ServiceLogEntity.models(ids: entities.map(\.id), in: context)
        guard !logs.isEmpty || entities.isEmpty else { throw IntentError.serviceLogNotFound }
        return logs
    }

    /// The vehicle a service belongs to. A service always has one in practice;
    /// an orphan (mid-delete sync) has nowhere to be logged.
    static func vehicle(of service: Service) throws -> Vehicle {
        guard let vehicle = service.vehicle else { throw IntentError.serviceNotFound }
        return vehicle
    }

    /// Finish a write: save, then refresh everything computed from the
    /// vehicle's schedules. Saving explicitly matters here — an intent can
    /// return and the process suspend before autosave runs.
    static func commit(_ vehicle: Vehicle, in context: ModelContext) throws {
        DerivedSurfaces.refresh(for: vehicle)
        try save(context)
    }

    /// Save and let Spotlight follow, for writes whose action already
    /// refreshed the derived surfaces (`ServiceDeleteAction`,
    /// `ServiceLogDeleteAction`).
    static func save(_ context: ModelContext) throws {
        try context.save()
        SpotlightIndexer.shared.scheduleReindex(from: context.container)
    }
}
