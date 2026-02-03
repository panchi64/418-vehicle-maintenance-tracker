//
//  L10n.swift
//  checkpoint
//
//  Typed localization keys for accessing localized strings.
//  This file provides a type-safe way to access strings from Localizable.strings.
//

import Foundation

enum L10n {
    // MARK: - Common

    static var commonCancel: String { localized("common.cancel") }
    static var commonBack: String { localized("common.back") }
    static var commonNext: String { localized("common.next") }
    static var commonSave: String { localized("common.save") }
    static var commonDone: String { localized("common.done") }
    static var commonDismiss: String { localized("common.dismiss") }
    static var commonDays: String { localized("common.days") }

    // MARK: - Vehicle

    static var vehicleAdd: String { localized("vehicle.add") }
    static var vehicleDetails: String { localized("vehicle.details") }
    static var vehicleNickname: String { localized("vehicle.nickname") }
    static var vehicleMake: String { localized("vehicle.make") }
    static var vehicleModel: String { localized("vehicle.model") }
    static var vehicleYear: String { localized("vehicle.year") }
    static var vehicleMakePlaceholder: String { localized("vehicle.make_placeholder") }
    static var vehicleModelPlaceholder: String { localized("vehicle.model_placeholder") }
    static var vehicleYearPlaceholder: String { localized("vehicle.year_placeholder") }
    static var vehicleNicknamePlaceholder: String { localized("vehicle.nickname_placeholder") }
    static var vehicleOptional: String { localized("vehicle.optional") }
    static var vehicleOdometer: String { localized("vehicle.odometer") }
    static var vehicleCurrentMileage: String { localized("vehicle.current_mileage") }
    static var vehicleMileagePlaceholder: String { localized("vehicle.mileage_placeholder") }
    static var vehicleIdentification: String { localized("vehicle.identification") }
    static var vehicleVIN: String { localized("vehicle.vin") }
    static var vehicleVINPlaceholder: String { localized("vehicle.vin_placeholder") }
    static var vehicleVINHelp: String { localized("vehicle.vin_help") }
    static var vehicleSpecifications: String { localized("vehicle.specifications") }
    static var vehicleTireSize: String { localized("vehicle.tire_size") }
    static var vehicleTireSizePlaceholder: String { localized("vehicle.tire_size_placeholder") }
    static var vehicleOilType: String { localized("vehicle.oil_type") }
    static var vehicleOilTypePlaceholder: String { localized("vehicle.oil_type_placeholder") }
    static var vehicleNotes: String { localized("vehicle.notes") }
    static var vehicleNotesPlaceholder: String { localized("vehicle.notes_placeholder") }
    static var vehicleSave: String { localized("vehicle.save") }
    static var vehicleSkipDetails: String { localized("vehicle.skip_details") }
    static var vehicleFirstVehicle: String { localized("vehicle.first_vehicle") }

    // MARK: - Add Vehicle Flow

    static func addVehicleStep(_ current: Int, _ total: Int) -> String {
        String(format: localized("addvehicle.step"), current, total)
    }

    static var addVehicleBasics: String { localized("addvehicle.basics") }
    static var addVehicleScanningVIN: String { localized("addvehicle.scanning_vin") }
    static var addVehicleScanningOdometer: String { localized("addvehicle.scanning_odometer") }
    static var addVehicleVINAlignGuide: String { localized("addvehicle.vin_align_guide") }
    static var addVehicleVINLookup: String { localized("addvehicle.vin_lookup") }
    static var addVehicleVINLookupLoading: String { localized("addvehicle.vin_lookup_loading") }

    // MARK: - Settings

    static var settingsTitle: String { localized("settings.title") }
    static var settingsDisplay: String { localized("settings.display") }
    static var settingsAlerts: String { localized("settings.alerts") }
    static var settingsWidgets: String { localized("settings.widgets") }
    static var settingsServiceBundling: String { localized("settings.service_bundling") }
    static var settingsDistanceUnit: String { localized("settings.distance_unit") }
    static var settingsMileageEstimation: String { localized("settings.mileage_estimation") }
    static var settingsMileageEstimationDesc: String { localized("settings.mileage_estimation_desc") }
    static var settingsDueSoonMileage: String { localized("settings.due_soon_mileage") }
    static var settingsDueSoonDays: String { localized("settings.due_soon_days") }
    static var settingsAutomaticIcon: String { localized("settings.automatic_icon") }
    static var settingsAutomaticIconDesc: String { localized("settings.automatic_icon_desc") }
    static var settingsBundleSuggestions: String { localized("settings.bundle_suggestions") }
    static var settingsBundleSuggestionsDesc: String { localized("settings.bundle_suggestions_desc") }
    static var settingsDefaultVehicle: String { localized("settings.default_vehicle") }
    static var settingsMileageDisplay: String { localized("settings.mileage_display") }
    static var settingsMileageWindow: String { localized("settings.mileage_window") }
    static var settingsDaysWindow: String { localized("settings.days_window") }

    // MARK: - Distance Unit Picker

    static var distanceMiles: String { localized("distance.miles") }
    static var distanceKilometers: String { localized("distance.kilometers") }
    static var distanceMilesDefault: String { localized("distance.miles_default") }
    static var distanceKilometersAbbr: String { localized("distance.kilometers_abbr") }
    static var distanceUnitTitle: String { localized("distance.unit_title") }

    // MARK: - Due Soon Threshold Pickers

    static var dueSoonMileageTitle: String { localized("duesoon.mileage_title") }
    static var dueSoonMileageDesc: String { localized("duesoon.mileage_desc") }
    static var dueSoonDaysTitle: String { localized("duesoon.days_title") }
    static var dueSoonDaysDesc: String { localized("duesoon.days_desc") }
    static var dueSoonDefault: String { localized("duesoon.default") }

    // MARK: - Errors

    static var errorRequiredField: String { localized("error.required_field") }
    static var errorInvalidVINFormat: String { localized("error.invalid_vin_format") }
    static var errorCouldNotReadOdometer: String { localized("error.could_not_read_odometer") }
    static var errorNetworkConnectionFailed: String { localized("error.network_connection_failed") }

    // MARK: - Helper

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
