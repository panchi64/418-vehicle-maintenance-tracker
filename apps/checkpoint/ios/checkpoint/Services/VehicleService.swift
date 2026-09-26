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
        return vehicle
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
        vehicle.notes = nilIfEmpty(fields.notes)

        let hadMarbete = vehicle.hasMarbeteExpiration
        vehicle.marbeteExpirationMonth = fields.marbeteExpirationMonth
        vehicle.marbeteExpirationYear = fields.marbeteExpirationYear
        if vehicle.hasMarbeteExpiration {
            NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        } else if hadMarbete {
            NotificationService.shared.cancelMarbeteNotifications(for: vehicle)
        }

        // Refresh pending service reminders so they pick up edits
        // (name, mileage) instead of firing with stale content
        NotificationService.shared.rescheduleNotifications(for: vehicle)

        AppIconService.shared.updateIcon(for: vehicle, services: vehicle.services ?? [])
        WidgetDataService.shared.updateWidget(for: vehicle)
    }

    private static func nilIfEmpty(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}
