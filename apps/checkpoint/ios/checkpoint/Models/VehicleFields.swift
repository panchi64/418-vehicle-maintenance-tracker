//
//  VehicleFields.swift
//  checkpoint
//
//  Every value a user can write to a vehicle, as plain values. The vehicle
//  forms edit one (`VehicleFormState`); `VehicleService` saves one, for the
//  forms and for App Intents alike. Empty strings mean "not set" — the service
//  stores them as nil.
//

import Foundation

struct VehicleFields: Equatable {
    var name = ""
    var make = ""
    var model = ""
    var year: Int?
    var currentMileage: Int?
    var vin = ""
    var licensePlate = ""
    var tireSize = ""
    var oilType = ""
    var notes = ""
    var marbeteExpirationMonth: Int?
    var marbeteExpirationYear: Int?
}

extension VehicleFields {
    /// The values `vehicle` holds now.
    init(vehicle: Vehicle) {
        self.init(
            name: vehicle.name,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.hasModelYear ? vehicle.year : nil,
            currentMileage: vehicle.currentMileage,
            vin: vehicle.vin ?? "",
            licensePlate: vehicle.licensePlate ?? "",
            tireSize: vehicle.tireSize ?? "",
            oilType: vehicle.oilType ?? "",
            notes: vehicle.notes ?? "",
            marbeteExpirationMonth: vehicle.marbeteExpirationMonth,
            marbeteExpirationYear: vehicle.marbeteExpirationYear
        )
    }
}
