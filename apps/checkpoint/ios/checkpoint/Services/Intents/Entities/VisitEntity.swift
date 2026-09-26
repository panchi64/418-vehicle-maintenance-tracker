//
//  VisitEntity.swift
//  checkpoint
//
//  One shop visit: several services, one honest total.
//

import AppIntents
import CoreSpotlight
import SwiftData

struct VisitEntity: ModelBackedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Service Visit", numericFormat: "\(placeholder: .int) service visits")
    }

    static var defaultQuery: VisitEntityQuery { VisitEntityQuery() }

    let id: UUID

    /// The shop, or the generic visit title when no shop was entered.
    @Property(title: "Title", indexingKey: \.displayName)
    var title: String

    @Property(title: "Shop", indexingKey: \.namedLocation)
    var shopName: String?

    @Property(title: "Vehicle")
    var vehicleName: String

    @Property(title: "Date", indexingKey: \.completionDate)
    var performedDate: Date

    /// In miles.
    @Property(title: "Mileage")
    var mileage: Int

    @Property(title: "Total")
    var total: IntentCurrencyAmount?

    @Property(title: "Category")
    var category: CostCategory?

    @Property(title: "Services")
    var serviceNames: [String]

    /// Receipt lines ("Labor", "Oil filter"), when itemized.
    @Property(title: "Line Items")
    var lineItems: [String]

    @Property(title: "Notes", indexingKey: \.comment)
    var notes: String?

    let vehicleID: UUID?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(performedDate.formatted(date: .abbreviated, time: .omitted)) · \(vehicleName)",
            image: .init(systemName: "wrench.and.screwdriver")
        )
    }

    var searchableText: [String] { [title, shopName ?? ""] + serviceNames }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.containerDisplayName = vehicleName
        attributes.keywords = serviceNames
        return attributes
    }

    @MainActor
    init(model visit: ServiceVisit) {
        id = visit.id
        vehicleID = visit.vehicle?.id
        title = visit.shopName.flatMap { $0.isEmpty ? nil : $0 } ?? L10n.rowVisitTitle
        shopName = visit.shopName
        vehicleName = visit.vehicle?.displayName ?? ""
        performedDate = visit.performedDate
        mileage = visit.mileageAtVisit
        total = .stored(visit.totalCost)
        category = visit.costCategory
        serviceNames = (visit.logs ?? []).compactMap { $0.service?.name }.sorted()
        lineItems = (visit.lineItems ?? [])
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.label)
            .filter { !$0.isEmpty }
        notes = visit.notes
    }

    /// Newest first.
    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [ServiceVisit] {
        let newestFirst = [SortDescriptor(\ServiceVisit.performedDate, order: .reverse)]
        let descriptor: FetchDescriptor<ServiceVisit>
        if let ids {
            descriptor = FetchDescriptor(predicate: #Predicate { ids.contains($0.id) }, sortBy: newestFirst)
        } else {
            descriptor = FetchDescriptor(sortBy: newestFirst)
        }
        return try context.fetch(descriptor)
    }
}

struct VisitEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VisitEntity] {
        try await EntityFetch.entities(VisitEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [VisitEntity] {
        try await EntityFetch.entities(VisitEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [VisitEntity] {
        try await EntityFetch.entities(VisitEntity.self, in: container)
    }
}
