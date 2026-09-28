import Foundation

/// The numbers behind contributing (PRODUCT.md §4.1, §4.2, §5, §6.1, §10),
/// kept in one place because every one of them is *proposed*.
nonisolated enum ContributionRules {
    /// A report snaps to the nearest place of the right kind within this
    /// many metres (§4.1); an area takes reports from inside or next to it.
    static func snapRadius(for kind: Place.Kind) -> Double {
        switch kind {
        case .station, .charger: 150
        case .business: 75
        case .roadSegment: 50
        case .area: ConfirmRules.areaRadius
        }
    }

    /// A repeat of the same type on the same place within this window is a
    /// confirmation, not a new report (§4.2).
    nonisolated static let repeatWindow: TimeInterval = .minutes(15)

    /// A repeated price must also be the same grade and within this many ¢/L.
    nonisolated static let priceRepeatTolerance = 1.0

    /// Deshacer stays this long after anything is sent (§4.2).
    nonisolated static let undoWindow: Duration = .seconds(5)

    /// A typed price further than this many ¢/L outside DACO's island range
    /// is held out of the answer until reviewed (§6.1).
    nonisolated static let priceOutlierMargin = 15.0

    /// A plausible pump price in ¢/L; anything outside is a typo, not a report.
    nonisolated static let plausiblePrice: ClosedRange<Double> = 30...300

    /// A verified owner's seal lasts this long before it is renewed (§5).
    nonisolated static let ownerVerificationLength: TimeInterval = .days(365)

    /// Wrong codes allowed before the owner has to ask for another call.
    nonisolated static let ownerCodeAttempts = 3

    /// The code the owner hears on the call has this many digits.
    nonisolated static let ownerCodeLength = 4
}
