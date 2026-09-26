//
//  VehicleService.swift
//  checkpoint
//
//  Creating and editing a vehicle, shared by the vehicle forms and App
//  Intents. The forms own presentation (haptics, toasts, analytics, dismissal,
//  the starter-schedule offer); this owns what a save *means* — the model
//  writes and the reminders, widget and icon that must follow them.
//

import Foundation
import SwiftData

enum VehicleService {

    /// Vehicles a free user can keep. Adding past it asks for Pro.
    nonisolated static let freeVehicleLimit = 3

    /// Whether adding one more vehicle to `vehicleCount` needs Pro.
    nonisolated static func requiresPro(toAddTo vehicleCount: Int, isPro: Bool) -> Bool {
        vehicleCount >= freeVehicleLimit && !isPro
    }

    /// Insert a vehicle built from `fields` and schedule its marbete reminders.
    /// Empty strings are stored as nil; a missing year is stored as 0, the
    /// model's "unknown".
    ///
    /// Does not check the Pro limit — callers gate on `requiresPro` first, so
    /// each can explain the limit its own way.
    @discardableResult
    static func create(_ fields: VehicleFields, in context: ModelContext) -> Vehicle {
        // `currentMileage` is required by every caller that can enforce it;
        // the fallback stays rather than trapping.
        let vehicle = Vehicle(
            name: fields.name,
            make: fields.make,
            model: fields.model,
            year: fields.year ?? 0,
            currentMileage: fields.currentMileage ?? 0,
            vin: nilIfEmpty(fields.vin),
            licensePlate: nilIfEmpty(fields.licensePlate),
            tireSize: nilIfEmpty(fields.tireSize),
            oilType: nilIfEmpty(fields.oilType),
            notes: nilIfEmpty(fields.notes)
        )

        vehicle.marbeteExpirationMonth = fields.marbeteExpirationMonth
        vehicle.marbeteExpirationYear = fields.marbeteExpirationYear
        if vehicle.hasMarbeteExpiration {
            NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        }

        context.insert(vehicle)
        // Add Vehicle's notes become the vehicle's first, pinned note — the
        // same legacy note a migrated V1 field becomes, mirrored in `notes`.
        VehicleNoteMigration.reconcile(vehicle, in: context)
        return vehicle
    }

    /// `fields` with the make, model and year it left empty filled from its
    /// VIN's NHTSA decode — what the forms do as a VIN is typed, for callers
    /// with no form (Siri, Shortcuts). Values already given win. Without a
    /// VIN, or with every field already filled, nothing is looked up.
    /// Throws `NHTSAError` (invalid VIN, offline, …).
    static func fillingFromVIN(
        _ fields: VehicleFields,
        using client: any NHTSAClient = NHTSAService.shared
    ) async throws -> VehicleFields {
        let vin = fields.vin.trimmingCharacters(in: .whitespaces)
        guard !vin.isEmpty else { return fields }
        var filled = fields
        filled.vin = vin.uppercased()
        let needsLookup = fields.make.trimmingCharacters(in: .whitespaces).isEmpty
            || fields.model.trimmingCharacters(in: .whitespaces).isEmpty
            || fields.year == nil
        guard needsLookup else { return filled }
        filled.fillEmpty(from: try await client.decodeVIN(filled.vin))
        return filled
    }

    /// Write `fields` onto `vehicle`, then refresh everything derived from it:
    /// marbete and service reminders (they quote the name and mileage), the
    /// app icon, and the widget snapshot.
    static func update(_ vehicle: Vehicle, with fields: VehicleFields, in context: ModelContext) {
        vehicle.name = fields.name
        vehicle.make = fields.make
        vehicle.model = fields.model
        vehicle.year = fields.year ?? 0
        // F11: an edited odometer is a manual reading — record it (timestamp +
        // snapshot) rather than overwrite the number and leave the estimate
        // engine measuring from a stale date. Unchanged means no new reading.
        if let mileage = fields.currentMileage, mileage != vehicle.currentMileage {
            vehicle.recordMileage(mileage, source: .manual, in: context)
        }
        vehicle.vin = nilIfEmpty(fields.vin)
        vehicle.licensePlate = nilIfEmpty(fields.licensePlate)
        vehicle.tireSize = nilIfEmpty(fields.tireSize)
        vehicle.oilType = nilIfEmpty(fields.oilType)
        // Notes are edited as notes now (`VehicleNoteService`); `notes` is
        // their mirror and never written from the vehicle form.

        let hadMarbete = vehicle.hasMarbeteExpiration
        vehicle.marbeteExpirationMonth = fields.marbeteExpirationMonth
        vehicle.marbeteExpirationYear = fields.marbeteExpirationYear
        if vehicle.hasMarbeteExpiration {
            NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        } else if hadMarbete {
            NotificationService.shared.cancelMarbeteNotifications(for: vehicle)
        }

        // Service reminders pick up the edits (name, mileage) instead of
        // firing with stale content; the icon and widget follow.
        DerivedSurfaces.refresh(for: vehicle)
    }

    private static func nilIfEmpty(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}
