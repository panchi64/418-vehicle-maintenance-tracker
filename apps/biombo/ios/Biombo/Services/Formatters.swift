import Foundation

enum Formatters {
    static let price: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static let distance: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions = [.naturalScale, .providedUnit]
        f.unitStyle = .medium
        f.numberFormatter.maximumFractionDigits = 1
        return f
    }()

    static func priceString(_ value: Double) -> String {
        price.string(from: value as NSNumber) ?? "$\(value)"
    }

    static func distanceString(meters: Double) -> String {
        distance.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }
}
