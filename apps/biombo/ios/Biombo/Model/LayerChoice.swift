import Foundation

/// The layers the user chose to draw, first in onboarding and then in Capas,
/// kept between launches as "power,water,gas". Crisis ignores it: every
/// service is drawn first then (§8).
nonisolated struct LayerChoice: RawRepresentable, Hashable, Sendable {
    var layers: Set<Layer>

    /// Where the choice is kept; unset until the user makes one.
    static let storageKey = "layerChoice"

    init(_ layers: Set<Layer>) {
        self.layers = layers
    }

    /// Unknown names (a layer a later build dropped) are skipped.
    init?(rawValue: String) {
        layers = Set(rawValue.split(separator: ",").compactMap { Layer(rawValue: String($0)) })
    }

    /// In Capas order, so the same choice always reads the same.
    var rawValue: String {
        Layer.allCases.filter(layers.contains).map(\.rawValue).joined(separator: ",")
    }
}

extension Layer {
    /// What is drawn before the user touches Capas this session: their
    /// choice on an ordinary day, the mode's defaults in crisis or before
    /// they ever chose.
    static func initiallyVisible(inCrisis isCrisis: Bool, chosen: Set<Layer>?) -> Set<Layer> {
        guard !isCrisis, let chosen else { return defaultVisible(inCrisis: isCrisis) }
        return chosen
    }
}
