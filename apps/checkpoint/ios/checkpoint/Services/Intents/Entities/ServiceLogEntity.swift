//
//  ServiceLogEntity.swift
//  checkpoint
//
//  One service history entry — "when did I last change the oil?". A log that
//  belongs to a Service Visit carries the visit's ID; its cost is the visit's
//  business (`ServiceLog.attributableCost`), so an un-itemized visit's logs
//  report no cost of their own rather than each claiming the total.
//

import AppIntents
import CoreSpotlight
import SwiftData

struct ServiceLogEntity: ModelBackedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Service Log", numericFormat: "\(placeholder: .int) service logs")
    }

    static var defaultQuery: ServiceLogEntityQuery { ServiceLogEntityQuery() }

    let id: UUID

    @Property(title: "Service", indexingKey: \.displayName)
    var serviceName: String

    @Property(title: "Vehicle")
    var vehicleName: String

    @Property(title: "Date", indexingKey: \.completionDate)
    var performedDate: Date

    /// In miles.
    @Property(title: "Mileage")
    var mileage: Int

    @Property(title: "Cost")
    var cost: IntentCurrencyAmount?

    @Property(title: "Category")
    var category: CostCategory?

    @Property(title: "Notes", indexingKey: \.comment)
    var notes: String?

    let vehicleID: UUID?
    let serviceID: UUID?
    let visitID: UUID?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(serviceName)",
            subtitle: "\(performedDate.formatted(date: .abbreviated, time: .omitted)) · \(vehicleName)",
            image: .init(systemName: "checkmark.circle")
        )
    }

    var searchableText: [String] { [serviceName, notes ?? ""] }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.containerDisplayName = vehicleName
        return attributes
    }

    @MainActor
    init(model log: ServiceLog) {
        id = log.id
        vehicleID = log.vehicle?.id
        serviceID = log.service?.id
        visitID = log.visit?.id
        serviceName = log.service?.name ?? L10n.rowServiceFallback
        vehicleName = log.vehicle?.displayName ?? ""
        performedDate = log.performedDate
        mileage = log.mileageAtService
        cost = .stored(log.attributableCost)
        category = log.attributableCost == nil ? nil : log.costCategory
        notes = log.notes
    }

    /// Newest first: suggestions lead with recent history.
    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [ServiceLog] {
        let newestFirst = [SortDescriptor(\ServiceLog.performedDate, order: .reverse)]
        let descriptor: FetchDescriptor<ServiceLog>
        if let ids {
            descriptor = FetchDescriptor(predicate: #Predicate { ids.contains($0.id) }, sortBy: newestFirst)
        } else {
            descriptor = FetchDescriptor(sortBy: newestFirst)
        }
        return try context.fetch(descriptor)
    }
}

struct ServiceLogEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [ServiceLogEntity] {
        try await EntityFetch.entities(ServiceLogEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [ServiceLogEntity] {
        try await EntityFetch.entities(ServiceLogEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [ServiceLogEntity] {
        try await EntityFetch.entities(ServiceLogEntity.self, in: container)
    }
}
