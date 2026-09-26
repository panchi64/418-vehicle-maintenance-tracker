//
//  Appointment.swift
//  checkpoint
//
//  A booked visit to a shop: when, where, and which tracked services it is
//  for. It is a plan, not a record — completing it opens the service form
//  prefilled from it (`Appointment.logPrefill`), and the log the user saves
//  there is the record. Added in `CheckpointSchemaV2`.
//
//  CloudKit shape: every attribute defaulted or optional, relationships
//  optional with inverses. Status is stored as a String for the reason
//  `ServiceAttachment.documentTypeRaw` gives.
//

import Foundation
import SwiftData

nonisolated enum AppointmentStatus: String, Codable, CaseIterable, Sendable {
    case scheduled
    case completed
    case cancelled
}

@Model
final class Appointment: Identifiable {
    var id: UUID = UUID()
    var vehicle: Vehicle?

    var startDate: Date = Date.now
    /// nil means the shop gave a start time only; `effectiveEndDate` fills it.
    var endDate: Date?

    var shopName: String = ""
    /// A street address, as typed or as Maps resolved it.
    var address: String?
    /// Set when a place was resolved (Maps, or a Siri place). Both or neither.
    var latitude: Double?
    var longitude: Double?

    /// What to ask or remember at the counter.
    var note: String?

    private var statusRaw: String = AppointmentStatus.scheduled.rawValue
    var createdAt: Date = Date.now
    /// When it was completed or cancelled.
    var closedAt: Date?

    /// The tracked services this visit is for. Many-to-many; the inverse is
    /// `Service.appointments`. `.nullify`: deleting either side leaves the
    /// other alone.
    @Relationship(deleteRule: .nullify, inverse: \Service.appointments)
    var services: [Service]? = []

    var status: AppointmentStatus {
        get { AppointmentStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }

    init(
        vehicle: Vehicle? = nil,
        startDate: Date,
        endDate: Date? = nil,
        shopName: String,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        note: String? = nil,
        services: [Service] = []
    ) {
        self.vehicle = vehicle
        self.startDate = startDate
        self.endDate = endDate
        self.shopName = shopName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.note = note
        self.services = services
    }
}
