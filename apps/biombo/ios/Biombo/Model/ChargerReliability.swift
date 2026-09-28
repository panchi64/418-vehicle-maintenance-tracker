import Foundation

/// A charger's 90-day record, tallied by the backend from Biombo reports only
/// (PRODUCT.md §6.7). External datasets never feed it; the reporters behind it
/// never leave the server, so only counts arrive.
nonisolated struct ChargerTally: Codable, Hashable, Sendable {
    let placeID: Place.ID
    /// Status reports in the window.
    var reports: Int
    /// Distinct devices behind them.
    var devices: Int
    /// How many said "Funciona".
    var works: Int
    /// The recency-weighted share of "Funciona", 0...1.
    var weightedWorksShare: Double
}

/// "Suele funcionar": reliability in words, never a percentage alone.
nonisolated enum ChargerReliability: Hashable, Sendable {
    case usuallyWorks
    case sometimesFails
    case oftenFails
    /// Too few reports: "Todavía no sabemos si suele funcionar".
    case unknown

    /// Shown once there are this many reports from this many devices (*proposed*).
    nonisolated static let minimumReports = 5
    nonisolated static let minimumDevices = 3
    /// Share thresholds for the words (*proposed*).
    nonisolated static let usuallyWorksShare = 0.8
    nonisolated static let sometimesFailsShare = 0.5
    /// The window the tally covers.
    nonisolated static let windowDays = 90

    init(_ tally: ChargerTally?) {
        guard let tally, tally.reports >= Self.minimumReports, tally.devices >= Self.minimumDevices else {
            self = .unknown
            return
        }
        switch tally.weightedWorksShare {
        case Self.usuallyWorksShare...: self = .usuallyWorks
        case Self.sometimesFailsShare...: self = .sometimesFails
        default: self = .oftenFails
        }
    }
}
