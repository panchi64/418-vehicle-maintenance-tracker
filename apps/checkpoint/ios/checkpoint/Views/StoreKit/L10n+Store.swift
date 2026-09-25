//
//  L10n+Store.swift
//  checkpoint
//
//  Strings for the Pro paywall, the theme reveal, and the tip prompt copy.
//  Keys are prefixed `store.` (paywall, reveal) and `tip.prompt.` (the
//  rotating tip-modal messages).
//

import Foundation

extension L10n {
    private static func store(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Pro paywall

    static var storeProTitle: String { store("store.pro.title") }
    static var storeProWhatYouGet: String { store("store.pro.whatYouGet") }
    static var storeProFeatureVehicles: String { store("store.pro.feature.vehicles") }
    static var storeProFeatureThemes: String { store("store.pro.feature.themes") }
    static var storeProFeatureAI: String { store("store.pro.feature.ai") }
    static var storeProFeatureInsights: String { store("store.pro.feature.insights") }
    static var storeProUnlock: String { store("store.pro.unlock") }
    static var storeProNavTitle: String { store("store.pro.navTitle") }
    /// "$9.99 LAUNCH PRICE" — the price is the only argument.
    static func storeProLaunchPrice(_ price: String) -> String {
        String(format: store("store.pro.launchPrice"), price)
    }

    // MARK: - Theme reveal

    static var storeRevealTitle: String { store("store.reveal.title") }
    static var storeRevealApply: String { store("store.reveal.apply") }
    static var storeRevealLater: String { store("store.reveal.later") }

    // MARK: - Tip prompt messages

    static var tipPromptClosing: String { store("tip.prompt.closing") }
    static var tipPromptClosingReturning: String { store("tip.prompt.closingReturning") }

    static func tipPromptMonthlyHeadline(_ amount: String) -> String {
        String(format: store("tip.prompt.monthly.headline"), amount)
    }
    static var tipPromptMonthlyBody: String { store("tip.prompt.monthly.body") }
    static var tipPromptMonthlyBodyReturning: String { store("tip.prompt.monthly.bodyReturning") }

    static func tipPromptAverageHeadline(_ amount: String) -> String {
        String(format: store("tip.prompt.average.headline"), amount)
    }
    static func tipPromptAverageBody(_ count: Int) -> String {
        String(format: store("tip.prompt.average.body"), count)
    }

    static func tipPromptAttentionHeadline(_ count: Int) -> String {
        count == 1
            ? store("tip.prompt.attention.headline.one")
            : String(format: store("tip.prompt.attention.headline.other"), count)
    }
    static func tipPromptAttentionBody(_ serviceName: String) -> String {
        String(format: store("tip.prompt.attention.body"), serviceName)
    }

    static func tipPromptMonitoredHeadline(_ count: Int) -> String {
        String(format: store("tip.prompt.monitored.headline"), count)
    }
    static var tipPromptMonitoredBody: String { store("tip.prompt.monitored.body") }

    static func tipPromptRecordsHeadline(_ months: Int) -> String {
        String(format: store("tip.prompt.records.headline"), months)
    }
    static func tipPromptRecordsBody(_ count: Int) -> String {
        String(format: store("tip.prompt.records.body"), count)
    }

    static func tipPromptTotalHeadline(_ amount: String) -> String {
        String(format: store("tip.prompt.total.headline"), amount)
    }
    static var tipPromptTotalBody: String { store("tip.prompt.total.body") }

    static func tipPromptVehiclesHeadline(_ count: Int) -> String {
        String(format: store("tip.prompt.vehicles.headline"), count)
    }
    static var tipPromptVehiclesBody: String { store("tip.prompt.vehicles.body") }

    static func tipPromptComingUpHeadline(_ serviceName: String) -> String {
        String(format: store("tip.prompt.comingUp.headline"), serviceName)
    }
    static var tipPromptComingUpBody: String { store("tip.prompt.comingUp.body") }

    static func tipPromptHistoryHeadline(_ months: Int) -> String {
        String(format: store("tip.prompt.history.headline"), months)
    }
    static var tipPromptHistoryBody: String { store("tip.prompt.history.body") }

    static var tipPromptThanksHeadline: String { store("tip.prompt.thanks.headline") }
    static var tipPromptThanksBody: String { store("tip.prompt.thanks.body") }

    static var tipPromptFallbackHeadline: String { store("tip.prompt.fallback.headline") }
    static var tipPromptFallbackBody: String { store("tip.prompt.fallback.body") }
}
