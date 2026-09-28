import Foundation

/// When an on-device summary earns its place (PRODUCT.md §3 principle 5,
/// §11 "Device tiers"): only where Apple Intelligence runs on this iPhone,
/// only over enough facts to need one, and never in crisis, when copy stays
/// plain templates. Everywhere else the rows already say every change, so
/// nothing is lost without it.
nonisolated enum SummaryGate {
    /// Fewer changes than this need no summary: the list says them.
    static let minimumFacts = 2

    static func shouldSummarize(factCount: Int, isModelAvailable: Bool, isCrisis: Bool) -> Bool {
        isModelAvailable && !isCrisis && factCount >= minimumFacts
    }
}
