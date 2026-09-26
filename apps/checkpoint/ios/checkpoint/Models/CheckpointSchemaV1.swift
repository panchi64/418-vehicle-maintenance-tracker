//
//  CheckpointSchemaV1.swift
//  checkpoint
//
//  The shipped V1 store shape, frozen. SwiftData tells schema versions apart
//  by hashing their models, so V1 cannot list the live classes once they have
//  changed: `Vehicle` now relates to `Appointment` and `VehicleNote`, which
//  would make V1 hash the same as V2 and leave the migration plan unable to
//  say which one an on-disk store is.
//
//  These nested copies keep exactly the stored properties, relationships,
//  delete rules and attribute options the app shipped with (entity names are
//  the unqualified class names, so they match the store). Behavior lives on
//  the live models; nothing here is used outside migration.
//
//  NEVER EDIT. A V1 store written by the shipped app must keep opening. The
//  on-disk migration test (`CheckpointMigrationTests`) opens a real V1 store
//  and fails if this drifts from it.
//

import Foundation
import SwiftData

enum CheckpointSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Vehicle.self,
            Service.self,
            ServiceLog.self,
            ServicePreset.self,
            MileageSnapshot.self,
            ServiceAttachment.self,
            RecallAcknowledgment.self,
            ServiceVisit.self,
            VisitLineItem.self,
        ]
    }

    @Model
    final class Vehicle {
        var id: UUID = UUID()
        var name: String = ""
        var make: String = ""
        var model: String = ""
        var year: Int = 0
        var currentMileage: Int = 0
        var vin: String?
        var licensePlate: String?
        var tireSize: String?
        var oilType: String?
        var notes: String?
        var mileageUpdatedAt: Date?
        var marbeteExpirationMonth: Int?
        var marbeteExpirationYear: Int?
        var marbeteNotificationID: String?

        @Relationship(deleteRule: .cascade, inverse: \Service.vehicle)
        var services: [Service]? = []

        @Relationship(deleteRule: .cascade, inverse: \ServiceLog.vehicle)
        var serviceLogs: [ServiceLog]? = []

        @Relationship(deleteRule: .cascade, inverse: \MileageSnapshot.vehicle)
        var mileageSnapshots: [MileageSnapshot]? = []

        @Relationship(deleteRule: .cascade, inverse: \ServiceVisit.vehicle)
        var serviceVisits: [ServiceVisit]? = []

        @Relationship(deleteRule: .nullify, inverse: \ServiceAttachment.vehicles)
        var documents: [ServiceAttachment]? = []

        init(name: String, make: String, model: String, year: Int, notes: String? = nil) {
            self.name = name
            self.make = make
            self.model = model
            self.year = year
            self.notes = notes
        }
    }

    @Model
    final class Service {
        var id: UUID = UUID()
        var name: String = ""
        var dueDate: Date?
        var dueMileage: Int?
        var lastPerformed: Date?
        var lastMileage: Int?
        var intervalMonths: Int?
        var intervalMiles: Int?
        var notificationID: String?
        var notes: String?
        var isRecurring: Bool = false

        var vehicle: Vehicle?

        @Relationship(deleteRule: .cascade, inverse: \ServiceLog.service)
        var logs: [ServiceLog]? = []

        init(name: String) {
            self.name = name
        }
    }

    @Model
    final class ServiceLog {
        var id: UUID = UUID()
        var service: Service?
        var vehicle: Vehicle?
        var performedDate: Date = Date.now
        var mileageAtService: Int = 0
        var cost: Decimal?
        var costCategory: CostCategory?
        var notes: String?
        var createdAt: Date = Date.now
        var visit: ServiceVisit?

        @Relationship(deleteRule: .nullify, inverse: \ServiceAttachment.serviceLog)
        var attachments: [ServiceAttachment]? = []

        init() {}
    }

    @Model
    final class ServicePreset {
        var name: String = ""
        private var categoryRawValue: String = ServiceCategory.other.rawValue
        var defaultIntervalMonths: Int?
        var defaultIntervalMiles: Int?
        var isCustom: Bool = false

        init(name: String) {
            self.name = name
        }
    }

    @Model
    final class MileageSnapshot {
        var id: UUID = UUID()
        var vehicle: Vehicle?
        var mileage: Int = 0
        var recordedAt: Date = Date.now
        private var sourceRawValue: String = MileageSource.manual.rawValue

        init(mileage: Int) {
            self.mileage = mileage
        }
    }

    @Model
    final class ServiceAttachment {
        var id: UUID = UUID()
        var serviceLog: ServiceLog?

        @Attribute(.externalStorage)
        var data: Data?

        @Attribute(.externalStorage)
        var thumbnailData: Data?

        var fileName: String = ""
        var mimeType: String = "image/jpeg"
        var createdAt: Date = Date.now
        var extractedText: String?
        var documentTypeRaw: String = DocumentType.receipt.rawValue
        var notes: String?
        var vehicles: [Vehicle]?

        init(fileName: String) {
            self.fileName = fileName
        }
    }

    @Model
    final class RecallAcknowledgment {
        var id: UUID = UUID()
        var vehicleID: UUID = UUID()
        var campaignNumber: String = ""
        private var statusRaw: String = RecallStatus.open.rawValue
        var snoozedUntil: Date?
        var updatedAt: Date = Date.now

        init() {}
    }

    @Model
    final class ServiceVisit {
        var id: UUID = UUID()
        var vehicle: Vehicle?
        var performedDate: Date = Date.now
        var mileageAtVisit: Int = 0
        var totalCost: Decimal?
        var costCategory: CostCategory?
        var isItemized: Bool = false
        var shopName: String?
        var notes: String?
        var createdAt: Date = Date.now

        @Relationship(deleteRule: .nullify, inverse: \ServiceLog.visit)
        var logs: [ServiceLog]? = []

        @Relationship(deleteRule: .cascade, inverse: \VisitLineItem.visit)
        var lineItems: [VisitLineItem]? = []

        init() {}
    }

    @Model
    final class VisitLineItem {
        var id: UUID = UUID()
        var visit: ServiceVisit?
        var label: String = ""
        var kind: VisitLineItemKind = VisitLineItemKind.other
        var amount: Decimal = 0
        var createdAt: Date = Date.now

        init() {}
    }
}
