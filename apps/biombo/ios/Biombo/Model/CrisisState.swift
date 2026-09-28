import Foundation

/// Crisis mode (PRODUCT.md §8): utility layers first, tighter budgets, plain copy.
/// `CrisisRules.step` moves it from one set of source readings to the next.
nonisolated struct CrisisState: Codable, Hashable, Sendable {
    /// What holds crisis mode on. While the mode waits out its all-clear hold,
    /// this keeps the triggers that turned it on.
    var triggers: [Trigger]
    var since: Date?
    /// A declaration can name municipios; empty means island-wide.
    var municipios: [String] = []
    /// When LUMA's island share first reached the on threshold; it must hold
    /// for `CrisisRules.lumaHold` before it counts.
    var lumaAboveSince: Date?
    /// When every automatic trigger last became clear; the mode ends after
    /// `CrisisRules.clearHold` of uninterrupted calm.
    var clearSince: Date?

    nonisolated enum Trigger: String, CaseIterable, Codable, Hashable, Sendable {
        case nwsWarning
        case lumaCustomersOut
        case dirsActivated
        case communityPowerAreas
        case declaration
    }

    var isActive: Bool { !triggers.isEmpty }

    nonisolated static let ordinary = CrisisState(triggers: [], since: nil)
}
