//
//  VehicleEntity.swift
//  checkpoint
//
//  A vehicle, as Siri, Shortcuts and Spotlight see it. Carries the reference
//  facts people ask about ("what oil does my Civic take?") as properties, so
//  Siri AI can answer from the entity without an intent per question.
//
//  App target only. The widget extension keeps its own lightweight
//  snapshot-backed `VehicleEntity` (CheckpointWidget/VehicleEntity.swift) for
//  its configuration picker; the two never share a target, and the widget's
//  keeps its name so saved widget configurations still resolve.
//
//  IDs are the vehicle's UUID — the same string the old shared entity used,
//  so Shortcuts saved against it still resolve.
//

import AppIntents
import CoreSpotlight
import SwiftData

struct VehicleEntity: ModelBackedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Vehicle", numericFormat: "\(placeholder: .int) vehicles")
    }

    static var defaultQuery: VehicleEntityQuery { VehicleEntityQuery() }

    let id: UUID

    @Property(title: "Name", indexingKey: \.displayName)
    var name: String

    @Property(title: "Make")
    var make: String

    @Property(title: "Model")
    var model: String

    /// nil when the year was never entered.
    @Property(title: "Year")
    var year: Int?

    /// The last recorded odometer reading, in miles.
    @Property(title: "Recorded Mileage")
    var recordedMileage: Int

    /// Projected from driving pace when a projection exists (see
    /// `Vehicle.mileageEstimate`), otherwise nil.
    @Property(title: "Estimated Mileage")
    var estimatedMileage: Int?

    @Property(title: "License Plate")
    var licensePlate: String?

    @Property(title: "VIN")
    var vin: String?

    @Property(title: "Tire Size")
    var tireSize: String?

    @Property(title: "Oil Type")
    var oilType: String?

    /// The last day of the marbete (PR registration tag) month, when set.
    @Property(title: "Marbete Expiration")
    var marbeteExpiration: Date?

    /// "2022 Toyota Camry".
    let identityLine: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: identityLine.isEmpty || identityLine == name ? nil : "\(identityLine)",
            image: .init(systemName: "car.fill")
        )
    }

    var searchableText: [String] {
        [name, make, model, identityLine, licensePlate ?? ""]
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.contentDescription = identityLine
        attributes.keywords = [make, model, licensePlate, vin].compactMap { $0 }.filter { !$0.isEmpty }
        return attributes
    }

    @MainActor
    init(model vehicle: Vehicle) {
        let estimate = vehicle.mileageEstimate
        id = vehicle.id
        identityLine = vehicle.identityLine
        name = vehicle.displayName
        make = vehicle.make
        model = vehicle.model
        year = vehicle.hasModelYear ? vehicle.year : nil
        recordedMileage = vehicle.currentMileage
        estimatedMileage = estimate.isEstimated ? estimate.effective : nil
        licensePlate = vehicle.licensePlate
        vin = vehicle.vin
        tireSize = vehicle.tireSize
        oilType = vehicle.oilType
        marbeteExpiration = vehicle.marbeteExpirationDate
    }

    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Vehicle] {
        let descriptor: FetchDescriptor<Vehicle>
        if let ids {
            descriptor = FetchDescriptor(predicate: #Predicate { ids.contains($0.id) }, sortBy: [SortDescriptor(\.name)])
        } else {
            descriptor = FetchDescriptor(sortBy: [SortDescriptor(\.name)])
        }
        return try context.fetch(descriptor)
    }
}

struct VehicleEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VehicleEntity] {
        try await EntityFetch.entities(VehicleEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [VehicleEntity] {
        try await EntityFetch.entities(VehicleEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [VehicleEntity] {
        try await EntityFetch.entities(VehicleEntity.self, in: container)
    }
}
