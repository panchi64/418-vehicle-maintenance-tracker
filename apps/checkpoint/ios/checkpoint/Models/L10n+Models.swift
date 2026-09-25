//
//  L10n+Models.swift
//  checkpoint
//
//  Display strings that the model and utility layers hand to views and to
//  the widget/Siri payloads: climate zones, seasonal reminders, due
//  descriptions, distance units, and form validation messages. Keys are
//  prefixed `climate.`, `seasonal.`, `desc.`, `unit.`, and `validation.`.
//

import Foundation

extension L10n {
    private static func model(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Climate zones

    static var climateColdWinterName: String { model("climate.coldWinter.name") }
    static var climateColdWinterDetail: String { model("climate.coldWinter.detail") }
    static var climateMildFourSeasonName: String { model("climate.mildFourSeason.name") }
    static var climateMildFourSeasonDetail: String { model("climate.mildFourSeason.detail") }
    static var climateHotDryName: String { model("climate.hotDry.name") }
    static var climateHotDryDetail: String { model("climate.hotDry.detail") }
    static var climateHotHumidName: String { model("climate.hotHumid.name") }
    static var climateHotHumidDetail: String { model("climate.hotHumid.detail") }
    static var climateTropicalName: String { model("climate.tropical.name") }
    static var climateTropicalDetail: String { model("climate.tropical.detail") }

    // MARK: - Seasonal reminders

    static var seasonalAntifreezeName: String { model("seasonal.antifreeze.name") }
    static var seasonalAntifreezeDetail: String { model("seasonal.antifreeze.detail") }
    static var seasonalWinterTiresName: String { model("seasonal.winterTires.name") }
    static var seasonalWinterTiresDetail: String { model("seasonal.winterTires.detail") }
    static var seasonalSummerTiresName: String { model("seasonal.summerTires.name") }
    static var seasonalSummerTiresDetail: String { model("seasonal.summerTires.detail") }
    static var seasonalSaltDamageName: String { model("seasonal.saltDamage.name") }
    static var seasonalSaltDamageDetail: String { model("seasonal.saltDamage.detail") }
    static var seasonalACCheckName: String { model("seasonal.acCheck.name") }
    static var seasonalACCheckDetail: String { model("seasonal.acCheck.detail") }
    static var seasonalWipersName: String { model("seasonal.wipers.name") }
    static var seasonalWipersDetail: String { model("seasonal.wipers.detail") }
    static var seasonalBatteryName: String { model("seasonal.battery.name") }
    static var seasonalBatteryDetail: String { model("seasonal.battery.detail") }
    static var seasonalCoolantName: String { model("seasonal.coolant.name") }
    static var seasonalCoolantDetail: String { model("seasonal.coolant.detail") }

    // MARK: - Due descriptions (widget, watch, Siri, cluster rows)

    static func descDaysOverdue(_ days: Int) -> String {
        String(format: model("desc.daysOverdue"), days)
    }
    static var descDueToday: String { model("desc.dueToday") }
    static var descDueTomorrow: String { model("desc.dueTomorrow") }
    static func descDueInDays(_ days: Int) -> String {
        String(format: model("desc.dueInDays"), days)
    }
    static var descDueNow: String { model("desc.dueNow") }
    /// "400 miles overdue" — the number, then the unit's full name.
    static func descDistanceOverdue(_ distance: String, _ unit: String) -> String {
        String(format: model("desc.distanceOverdue"), distance, unit)
    }
    /// "1,200 miles remaining" — the number, then the unit's full name.
    static func descDistanceRemaining(_ distance: String, _ unit: String) -> String {
        String(format: model("desc.distanceRemaining"), distance, unit)
    }
    static var descScheduled: String { model("desc.scheduled") }
    static var descMarbeteRenewal: String { model("desc.marbeteRenewal") }
    static var descMarbeteSet: String { model("desc.marbeteSet") }
    static var descCompletedViaWidget: String { model("desc.completedViaWidget") }

    // MARK: - Odometer freshness

    static var descMileageNeverUpdated: String { model("desc.mileage.never") }
    static var descMileageUpdatedToday: String { model("desc.mileage.today") }
    static var descMileageUpdatedYesterday: String { model("desc.mileage.yesterday") }
    static func descMileageUpdatedDaysAgo(_ days: Int) -> String {
        String(format: model("desc.mileage.daysAgo"), days)
    }

    // MARK: - Distance units

    static var unitMiles: String { model("unit.miles") }
    static var unitKilometers: String { model("unit.kilometers") }
    static var unitMilesLower: String { model("unit.miles.lower") }
    static var unitKilometersLower: String { model("unit.kilometers.lower") }

    // MARK: - Form validation

    static var validationInvalidAmount: String { model("validation.invalidAmount") }
    static func validationMileageBelowLogged(_ mileage: String) -> String {
        String(format: model("validation.mileageBelowLogged"), mileage)
    }
    static func validationMileageJump(_ jump: String) -> String {
        String(format: model("validation.mileageJump"), jump)
    }
    static func validationCostAnomaly(_ serviceName: String) -> String {
        String(format: model("validation.costAnomaly"), serviceName)
    }
    /// "LAST TIME: $48 · MAR 12, 2026" — amount, then date.
    static func validationPriorCost(_ amount: String, _ date: String) -> String {
        String(format: model("validation.priorCost"), amount, date)
    }
}
