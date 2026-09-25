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
        static let lastTipPromptDate = "purchaseLastTipPromptDate"
        static let tipPromptShownCount = "purchaseTipPromptShownCount"
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

    /// When the user last tipped — used for the post-tip cooldown
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

    /// When the app last prompted for a tip — drives the 30-day spacing.
    var lastTipPromptDate: Date? {
        get { defaults.object(forKey: Keys.lastTipPromptDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastTipPromptDate) }
    }

    /// Lifetime count of app-initiated tip prompts — drives the cap.
    var tipPromptShownCount: Int {
        get { defaults.integer(forKey: Keys.tipPromptShownCount) }
        set { defaults.set(newValue, forKey: Keys.tipPromptShownCount) }
    }

    // MARK: - Tip Prompt Gating

    /// The stored counters, as the policy that decides whether to prompt.
    /// The rules and their values live in `TipPromptPolicy`.
    var tipPromptPolicy: TipPromptPolicy {
        TipPromptPolicy(
            completedActionCount: completedActionCount,
            dismissCount: tipPromptDismissCount,
            promptsShown: tipPromptShownCount,
            hasTipped: totalTipCount > 0,
            lastTipDate: lastTipDate,
            lastPromptDate: lastTipPromptDate,
            shownThisSession: hasShownTipModalThisSession
        )
    }

    var shouldShowTipPrompt: Bool {
        tipPromptPolicy.shouldShow()
    }

    /// Record that the app prompted — starts the spacing window and counts
    /// toward the lifetime cap.
    func recordTipPromptShown(at date: Date = .now) {
        hasShownTipModalThisSession = true
        lastTipPromptDate = date
        tipPromptShownCount += 1
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
            Keys.completedActionCount: 0,
            Keys.tipPromptShownCount: 0
        ])
    }
}
