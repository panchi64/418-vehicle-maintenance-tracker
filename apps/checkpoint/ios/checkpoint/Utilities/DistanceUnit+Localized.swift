//
//  DistanceUnit+Localized.swift
//  checkpoint
//
//  Localized unit names. Kept out of DistanceUnit.swift because that file is
//  shared with the Watch app, which doesn't have L10n.
//

import Foundation

extension DistanceUnit {
    /// Localized lowercase name for running text: "miles" / "millas"
    var fullName: String {
        switch self {
        case .miles: return L10n.unitMilesLower
        case .kilometers: return L10n.unitKilometersLower
        }
    }

    /// Localized name for pickers and settings rows: "Miles" / "Millas"
    var displayName: String {
        switch self {
        case .miles: return L10n.unitMiles
        case .kilometers: return L10n.unitKilometers
        }
    }
}
