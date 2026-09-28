import Foundation

/// Visitor mode (PRODUCT.md §2): a visitor reads Biombo in English, from
/// the system language or Ajustes › Biombo › Idioma. Their station detail
/// adds "New to Puerto Rico?": what DACO is, today's range, and the unit
/// switch. Units stay their own setting, gallons by default for a US region.
nonisolated enum VisitorGuide {
    static func isVisitor(_ locale: Locale) -> Bool {
        locale.language.languageCode == .english
    }

    /// On a station, past peek, on ordinary days, until "Got it". In crisis
    /// promotional and explanatory extras step back (§3 "Tone matches stakes").
    static func shows(on placeKind: Place.Kind?, tier: DisclosureTier, locale: Locale, isCrisis: Bool, isDismissed: Bool) -> Bool {
        placeKind == .station && tier != .peek && isVisitor(locale) && !isCrisis && !isDismissed
    }

    /// Pumps in Puerto Rico show litres, so a price read in gallons also
    /// says what the pump will show.
    static func showsPumpPrice(in unit: PriceUnit) -> Bool {
        unit == .gallon
    }
}
