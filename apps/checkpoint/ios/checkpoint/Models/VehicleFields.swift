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
    /// Add Vehicle only: becomes the vehicle's first, pinned note. Edit
    /// Vehicle doesn't write it — notes are edited as notes.
    var notes = ""
    var marbeteExpirationMonth: Int?
    var marbeteExpirationYear: Int?
}

extension VehicleFields {
    /// The fields a VIN decode can fill.
    enum DecodedField: Hashable {
        case make, model, year
    }

    /// Fill only the make, model and year still empty from a VIN decode — a
    /// lookup never overwrites what the user typed or said — and return which
    /// it filled. The vehicle forms and `VehicleService.fillingFromVIN` share
    /// this rule.
    @discardableResult
    mutating func fillEmpty(from result: VINDecodeResult) -> Set<DecodedField> {
        var filled: Set<DecodedField> = []
        if make.trimmingCharacters(in: .whitespaces).isEmpty, !result.make.isEmpty {
            make = result.make
            filled.insert(.make)
        }
        if model.trimmingCharacters(in: .whitespaces).isEmpty, !result.model.isEmpty {
            model = result.model
            filled.insert(.model)
        }
        if year == nil, let decodedYear = result.modelYear {
            year = decodedYear
            filled.insert(.year)
        }
        return filled
    }

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
