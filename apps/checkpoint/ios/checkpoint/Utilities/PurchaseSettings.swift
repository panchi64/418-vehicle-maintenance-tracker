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
        static let lastTipDate = "purchaseLastTipDate"
        static let tipPromptDismissCount = "purchaseTipPromptDismissCount"
        static let completedActionCount = "purchaseCompletedActionCount"
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

    /// When the user last tipped — used for 30-day cooldown
    var lastTipDate: Date? {
        get { defaults.object(forKey: Keys.lastTipDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastTipDate) }
    }

    /// How many times the user has dismissed the tip prompt — drives progressive backoff
    var tipPromptDismissCount: Int {
        get { defaults.integer(forKey: Keys.tipPromptDismissCount) }
        set { defaults.set(newValue, forKey: Keys.tipPromptDismissCount) }
    }

    /// Running count of completed actions since last tip prompt was shown
    var completedActionCount: Int {
        get { defaults.integer(forKey: Keys.completedActionCount) }
        set { defaults.set(newValue, forKey: Keys.completedActionCount) }
    }

    // MARK: - Tip Prompt Gating

    /// Number of days to suppress prompts after a tip
    nonisolated static let tipCooldownDays = 30

    /// Base number of actions before first prompt
    nonisolated static let baseActionThreshold = 3

    /// Additional actions required per previous dismiss (progressive backoff)
    nonisolated static let dismissBackoffIncrement = 3

    /// Maximum action threshold (caps the backoff)
    nonisolated static let maxActionThreshold = 15

    /// The current action threshold based on how many times the user has dismissed
    var currentActionThreshold: Int {
        min(
            Self.baseActionThreshold + (tipPromptDismissCount * Self.dismissBackoffIncrement),
            Self.maxActionThreshold
        )
    }

    /// Whether the tip cooldown period has elapsed since the last tip
    var isTipCooldownExpired: Bool {
        guard let lastTip = lastTipDate else { return true }
        let daysSinceTip = Calendar.current.dateComponents([.day], from: lastTip, to: Date()).day ?? 0
        return daysSinceTip >= Self.tipCooldownDays
    }

    /// Whether enough actions have been completed to show a prompt
    var hasReachedActionThreshold: Bool {
        completedActionCount >= currentActionThreshold
    }

    /// Whether the tip prompt should be shown (all conditions met)
    var shouldShowTipPrompt: Bool {
        !hasShownTipModalThisSession
        && isTipCooldownExpired
        && hasReachedActionThreshold
    }

    /// Record that a tip was made — resets counters and starts cooldown
    func recordTip() {
        totalTipCount += 1
        lastTipDate = Date()
        completedActionCount = 0
        tipPromptDismissCount = 0
    }

    /// Record that the user dismissed the prompt — increases backoff
    func recordTipPromptDismiss() {
        tipPromptDismissCount += 1
        completedActionCount = 0
    }

    /// Increment the completed action counter
    func recordCompletedAction() {
        completedActionCount += 1
    }

    private init() {}

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.isPro: false,
            Keys.totalTipCount: 0,
            Keys.ownedThemeIDs: [String](),
            Keys.tipPromptDismissCount: 0,
            Keys.completedActionCount: 0
        ])
    }
}
