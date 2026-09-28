/// The map's ground: Pintado is the painted island at wide zoom; Sencillo is
/// plain. The user picks in Capas; crisis, Increase Contrast and Reduce
/// Transparency force Sencillo (direction §1.1).
nonisolated enum MapGround: String, CaseIterable, Sendable {
    case painted
    case plain

    /// Where the user's choice is kept.
    static let storageKey = "mapGround"

    /// Whether something other than the user decides: then Sencillo, always.
    static func isForced(isCrisis: Bool, increasedContrast: Bool, reduceTransparency: Bool) -> Bool {
        isCrisis || increasedContrast || reduceTransparency
    }

    /// The ground actually drawn.
    func effective(isCrisis: Bool, increasedContrast: Bool, reduceTransparency: Bool) -> MapGround {
        Self.isForced(isCrisis: isCrisis, increasedContrast: increasedContrast, reduceTransparency: reduceTransparency) ? .plain : self
    }
}
