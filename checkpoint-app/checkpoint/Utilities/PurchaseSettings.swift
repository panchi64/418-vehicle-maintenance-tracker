//
//  PurchaseSettings.swift
//  checkpoint
//
//  Settings for in-app purchase state persistence
//

import Foundation

@MainActor
final class PurchaseSettings {
    static let shared = PurchaseSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isPro = "purchaseIsPro"
        static let totalTipCount = "purchaseTotalTipCount"
        static let ownedThemeIDs = "purchaseOwnedThemeIDs"
    }

    var isPro: Bool {
        get { defaults.bool(forKey: Keys.isPro) }
        set { defaults.set(newValue, forKey: Keys.isPro) }
    }

    /// Reset on each app launch — not persisted
    var hasShownTipModalThisSession: Bool = false

    var totalTipCount: Int {
        get { defaults.integer(forKey: Keys.totalTipCount) }
        set { defaults.set(newValue, forKey: Keys.totalTipCount) }
    }

    var ownedThemeIDs: [String] {
        get { defaults.stringArray(forKey: Keys.ownedThemeIDs) ?? [] }
        set { defaults.set(newValue, forKey: Keys.ownedThemeIDs) }
    }

    private init() {}

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.isPro: false,
            Keys.totalTipCount: 0,
            Keys.ownedThemeIDs: [String]()
        ])
    }
}
