import Foundation

/// The small choices Biombo keeps in the app's defaults, beside the stores'
/// own saved JSON. "Borrar mis datos" resets every one (PRODUCT.md §13).
nonisolated enum Preferences {
    /// The first run finished or was skipped.
    static let hasOnboarded = "hasOnboarded"
    /// "Got it" on the visitor's "New to Puerto Rico?" card.
    static let visitorGuideDismissed = "visitorGuideDismissed"
    /// Siri tips, each dismissed for good.
    static let quickReportSiriTip = "siriTip.quickReport"
    static let watchListSiriTip = "siriTip.watchList"

    static var erasable: [String] {
        [
            PriceUnit.storageKey, MapGround.storageKey, LayerChoice.storageKey,
            hasOnboarded, visitorGuideDismissed, quickReportSiriTip, watchListSiriTip
        ]
    }
}
