@testable import Biombo
import Foundation
import Testing

@Suite("Numbers for glancing")
struct GlanceNumbersTests {
    let locale = Locale(identifier: "en_US")

    @Test("Prices drop trailing zeros only on whole dollars", arguments: [
        (99.0, "$0.99"),
        (100.0, "$1"),
        (110.0, "$1.10"),
        (99.6, "$1"),
    ])
    func litrePrices(centsPerLitre: Double, expected: String) {
        let price = FuelPrice(grade: .regular, centsPerLitre: centsPerLitre)
        #expect(GlanceNumbers.price(price, unit: .litre, locale: locale) == expected)
    }

    @Test("Gallons convert from ¢/L before rounding")
    func gallonPrice() {
        let price = FuelPrice(grade: .regular, centsPerLitre: 99)
        // 99 × 3.78541 = 374.76¢ → $3.75
        #expect(GlanceNumbers.cents(price, unit: .gallon) == 375)
        #expect(GlanceNumbers.price(price, unit: .gallon, locale: locale) == "$3.75")
    }

    @Test("Distances: one decimal under 10 km, whole above, never 1.0", arguments: [
        (820.0, "0.8 km"),
        (1_000.0, "1 km"),
        (9_440.0, "9.4 km"),
        (12_300.0, "12 km"),
        (20.0, "0.1 km"),
    ])
    func distances(meters: Double, expected: String) {
        // Formatted as one atom: the space before the unit never breaks the line.
        #expect(GlanceNumbers.distance(meters: meters, locale: locale) == expected.unbroken)
        #expect(!GlanceNumbers.distance(meters: meters, locale: locale).contains(" "))
    }

    @Test("Haversine distance is in metres")
    func haversine() {
        let sanJuan = GeoPoint(18.4655, -66.1057)
        let ponce = GeoPoint(18.0111, -66.6141)
        let kilometres = sanJuan.distance(to: ponce) / 1000
        #expect((70...77).contains(kilometres))
    }
}
