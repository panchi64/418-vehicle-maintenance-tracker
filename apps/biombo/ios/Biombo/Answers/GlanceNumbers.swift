import Foundation

/// The unit prices are shown in. A setting separate from language (§2);
/// litres by default in Puerto Rico.
nonisolated enum PriceUnit: String, CaseIterable, Codable, Hashable, Sendable {
    case litre
    case gallon

    /// Where the user's choice is kept; unset until they pick one.
    nonisolated static let storageKey = "priceUnit"

    /// Before the user picks: gallons for a US mainland region, litres
    /// anywhere else, Puerto Rico included (§2).
    static func regionDefault(_ region: Locale.Region?) -> PriceUnit {
        region == .unitedStates ? .gallon : .litre
    }

    /// The unit in use: the user's pick, else the region's default.
    static func resolved(_ stored: PriceUnit?, region: Locale.Region?) -> PriceUnit {
        stored ?? regionDefault(region)
    }

    /// The unit in use on this device, for the device's region.
    static func current(stored: PriceUnit?) -> PriceUnit {
        resolved(stored, region: Locale.current.region)
    }

    /// The unit in use, read from the app's defaults (for an App Intent,
    /// which has no `@AppStorage`).
    static func current(in defaults: UserDefaults = .standard) -> PriceUnit {
        current(stored: defaults.string(forKey: storageKey).flatMap(PriceUnit.init(rawValue:)))
    }
}

/// Numbers formatted for glancing (PRODUCT.md §3 "Numbers for glancing").
nonisolated enum GlanceNumbers {
    /// Whole cents in `unit`, converted before rounding (§4.2).
    static func cents(_ price: FuelPrice, unit: PriceUnit) -> Int {
        let raw = unit == .litre ? price.centsPerLitre : price.centsPerGallon
        return Int(raw.rounded())
    }

    /// The size of a price difference in whole cents of `unit`, converted
    /// before rounding: 3¢/L is 11¢/gal.
    static func difference(centsPerLitre: Double, unit: PriceUnit) -> Int {
        let raw = unit == .litre ? centsPerLitre : centsPerLitre * FuelPrice.litresPerGallon
        return Int(abs(raw).rounded())
    }

    /// "$0.99", "$1", "$1.10": no trailing zeros past a whole dollar.
    static func price(_ price: FuelPrice, unit: PriceUnit, locale: Locale) -> String {
        dollars(cents: cents(price, unit: unit), locale: locale)
    }

    static func dollars(cents: Int, locale: Locale) -> String {
        let amount = Decimal(cents) / 100
        let digits = cents.isMultiple(of: 100) ? 0 : 2
        return amount.formatted(.currency(code: "USD").precision(.fractionLength(digits)).locale(locale))
    }

    /// "0.8 km" under 10 km, "12 km" above, and never "1.0".
    static func distance(meters: Double, locale: Locale) -> String {
        let kilometres = max(meters, 100) / 1000
        let value = kilometres < 10 ? (kilometres * 10).rounded() / 10 : kilometres.rounded()
        let style = Measurement<UnitLength>.FormatStyle(
            width: .abbreviated,
            locale: locale,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(0...1)).locale(locale)
        )
        return Measurement(value: value, unit: UnitLength.kilometers).formatted(style).unbroken
    }
}

extension String {
    /// A glance atom ("3.3 km", "6 a. m.") that never breaks across lines.
    nonisolated var unbroken: String {
        replacingOccurrences(of: " ", with: "\u{00A0}")
    }
}
