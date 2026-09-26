//
//  OpenEntityIntents.swift
//  checkpoint
//
//  `.system.open` (iOS 27) for each entity Siri can name: "open my oil
//  change", "show the Civic". An open intent takes one target type, so each
//  entity gets a small intent; all of them land through `EntityRoutes` and
//  `PendingRouteStore`, the path notifications and widgets use. The photo
//  and file opens live with their schemas (`PhotoIntents`,
//  `DocumentFileEntity`).
//

import AppIntents
import SwiftData

@available(iOS 27, *)
@AppIntent(schema: .system.open)
struct OpenVehicleIntent {
    @Dependency var container: ModelContainer
    var target: VehicleEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.vehicle(target.id, in: container.mainContext))
        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .system.open)
struct OpenServiceDetailIntent {  // `OpenServiceIntent` is the widget's row tap.
    @Dependency var container: ModelContainer
    var target: ServiceEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.service(target.id, in: container.mainContext))
        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .system.open)
struct OpenServiceLogIntent {
    @Dependency var container: ModelContainer
    var target: ServiceLogEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.serviceLog(target.id, in: container.mainContext))
        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .system.open)
struct OpenVisitIntent {
    @Dependency var container: ModelContainer
    var target: VisitEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.visit(target.id, in: container.mainContext))
        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .system.open)
struct OpenDocumentIntent {
    @Dependency var container: ModelContainer
    var target: DocumentEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.document(target.id, in: container.mainContext))
        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .system.open)
struct OpenServiceReminderIntent {
    @Dependency var container: ModelContainer
    var target: ServiceReminderEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.service(target.id, in: container.mainContext))
        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .system.open)
struct OpenVehicleListIntent {
    @Dependency var container: ModelContainer
    var target: VehicleListEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.vehicle(target.id, in: container.mainContext))
        return .result()
    }
}
