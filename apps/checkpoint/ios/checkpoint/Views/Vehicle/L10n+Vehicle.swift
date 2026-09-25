//
//  L10n+Vehicle.swift
//  checkpoint
//
//  Strings added for the vehicle forms and the starter schedule offered after
//  a vehicle is added. Keys are prefixed `vehicle.`; older vehicle accessors
//  stay in `L10n.swift`.
//

import Foundation

extension L10n {
    private static func vehicle(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - VIN

    /// The lookup succeeded but every field it fills already had a value.
    static var vehicleVINNothingNew: String { vehicle("vehicle.vin.nothingNew") }

    // MARK: - Starter schedule

    static var vehicleStarterTitle: String { vehicle("vehicle.starter.title") }
    static var vehicleStarterIntro: String { vehicle("vehicle.starter.intro") }
    static var vehicleStarterNoneSelected: String { vehicle("vehicle.starter.noneSelected") }
    static func vehicleStarterAdd(_ count: Int) -> String {
        String(format: vehicle("vehicle.starter.add"), count)
    }
    static var vehicleStarterLastDone: String { vehicle("vehicle.starter.lastDone") }
    static var vehicleStarterLastDoneUnknown: String { vehicle("vehicle.starter.lastDone.unknown") }
    static var vehicleStarterLastDoneDate: String { vehicle("vehicle.starter.lastDone.date") }
    static var vehicleStarterLastDoneMileage: String { vehicle("vehicle.starter.lastDone.mileage") }
    static func vehicleStarterToastAdded(_ count: Int) -> String {
        String(format: vehicle("vehicle.starter.toastAdded"), count)
    }
}
