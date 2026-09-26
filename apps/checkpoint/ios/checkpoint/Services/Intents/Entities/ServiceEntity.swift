//
//  ServiceEntity.swift
//  checkpoint
//
//  A tracked service (a reminder, in Siri's terms): what is due, when, and
//  how often it recurs. Status is judged against the vehicle's effective
//  mileage, the same value every list in the app uses.
//

import AppIntents
import CoreSpotlight
import SwiftData

struct ServiceEntity: ModelBackedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Service", numericFormat: "\(placeholder: .int) services")
    }

    static var defaultQuery: ServiceEntityQuery { ServiceEntityQuery() }

    let id: UUID

    @Property(title: "Name", indexingKey: \.displayName)
    var name: String

    @Property(title: "Vehicle")
    var vehicleName: String

    @Property(title: "Status")
    var status: ServiceStatus

    @Property(title: "Due Date", indexingKey: \.dueDate)
    var dueDate: Date?

    /// In miles.
    @Property(title: "Due Mileage")
    var dueMileage: Int?

    @Property(title: "Interval (Months)")
    var intervalMonths: Int?

    /// In miles.
    @Property(title: "Interval (Miles)")
    var intervalMiles: Int?

    @Property(title: "Last Performed")
    var lastPerformed: Date?

    @Property(title: "Notes", indexingKey: \.comment)
    var notes: String?

    let vehicleID: UUID?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(vehicleName)",
            image: .init(systemName: "wrench.and.screwdriver.fill")
        )
    }

    var searchableText: [String] { [name] }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.containerDisplayName = vehicleName
        return attributes
    }

    @MainActor
    init(model service: Service) {
        let vehicle = service.vehicle
        id = service.id
        vehicleID = vehicle?.id
        name = service.name
        vehicleName = vehicle?.displayName ?? ""
        status = vehicle.map { service.status(on: $0) } ?? .neutral
        dueDate = service.dueDate
        dueMileage = service.dueMileage
        intervalMonths = Self.positive(service.intervalMonths)
        intervalMiles = Self.positive(service.intervalMiles)
        lastPerformed = service.lastPerformed
        notes = service.notes
    }

    /// A zero interval means "no policy" (`Service.hasIntervalPolicy`).
    private static func positive(_ value: Int?) -> Int? {
        value.flatMap { $0 > 0 ? $0 : nil }
    }

    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Service] {
        let descriptor: FetchDescriptor<Service>
        if let ids {
            descriptor = FetchDescriptor(predicate: #Predicate { ids.contains($0.id) }, sortBy: [SortDescriptor(\.name)])
        } else {
            descriptor = FetchDescriptor(sortBy: [SortDescriptor(\.name)])
        }
        return try context.fetch(descriptor)
    }
}

struct ServiceEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [ServiceEntity] {
        try await EntityFetch.entities(ServiceEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [ServiceEntity] {
        try await EntityFetch.entities(ServiceEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [ServiceEntity] {
        try await EntityFetch.entities(ServiceEntity.self, in: container)
    }
}
