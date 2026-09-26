//
//  AppointmentEntity.swift
//  checkpoint
//
//  A booked shop visit, for Siri, Shortcuts and Spotlight ("when's my oil
//  change appointment?", "move my Firestone appointment to Friday").
//

import AppIntents
import CoreSpotlight
import SwiftData

struct AppointmentEntity: ModelBackedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Shop Appointment", numericFormat: "\(placeholder: .int) shop appointments")
    }

    static var defaultQuery: AppointmentEntityQuery { AppointmentEntityQuery() }

    let id: UUID

    @Property(title: "Shop", indexingKey: \.displayName)
    var shopName: String

    @Property(title: "Starts", indexingKey: \.startDate)
    var startDate: Date

    @Property(title: "Ends", indexingKey: \.endDate)
    var endDate: Date

    @Property(title: "Address", indexingKey: \.namedLocation)
    var address: String?

    @Property(title: "Vehicle")
    var vehicleName: String

    @Property(title: "Services")
    var serviceNames: [String]

    @Property(title: "Status")
    var status: AppointmentStatus

    @Property(title: "Note", indexingKey: \.comment)
    var note: String?

    let vehicleID: UUID?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(shopName)",
            subtitle: "\(startDate.formatted(date: .abbreviated, time: .shortened)) · \(vehicleName)",
            image: .init(systemName: "calendar.badge.clock")
        )
    }

    var searchableText: [String] { [shopName, address ?? ""] + serviceNames }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.containerDisplayName = vehicleName
        attributes.keywords = serviceNames
        return attributes
    }

    @MainActor
    init(model appointment: Appointment) {
        id = appointment.id
        vehicleID = appointment.vehicle?.id
        shopName = appointment.trimmedShopName ?? L10n.appointmentShopFallback
        startDate = appointment.startDate
        endDate = appointment.effectiveEndDate
        address = appointment.address
        vehicleName = appointment.vehicle?.displayName ?? ""
        serviceNames = appointment.sortedServices.map(\.name)
        status = appointment.status
        note = appointment.note
    }

    /// Scheduled first (soonest first), then closed ones newest first.
    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Appointment] {
        let descriptor: FetchDescriptor<Appointment>
        if let ids {
            descriptor = FetchDescriptor(predicate: #Predicate { ids.contains($0.id) })
        } else {
            descriptor = FetchDescriptor()
        }
        let all = try context.fetch(descriptor)
        let scheduled = Appointment.scheduled(all)
        let closed = all.filter { !$0.isScheduled }.sorted { $0.startDate > $1.startDate }
        return scheduled + closed
    }
}

struct AppointmentEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [AppointmentEntity] {
        try await EntityFetch.entities(AppointmentEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [AppointmentEntity] {
        try await EntityFetch.entities(AppointmentEntity.self, matching: string, in: container)
    }

    /// Only visits still ahead: those are the ones Siri is asked about.
    func suggestedEntities() async throws -> [AppointmentEntity] {
        try await EntityFetch.entities(AppointmentEntity.self, in: container).filter { $0.status == .scheduled }
    }
}
