//
//  L10n+Home.swift
//  checkpoint
//
//  Home tab strings. Keys are prefixed `home.`; kept apart from L10n.swift so
//  parallel work on other tabs doesn't collide in one file.
//

import Foundation

extension L10n {
    private static func home(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Next Up

    static var homeNextUp: String { home("home.nextUp") }
    static var homeNextUpEmpty: String { home("home.nextUp.empty") }
    static var homeMarkDone: String { home("home.markDone") }
    static var homeMarkRenewed: String { home("home.markRenewed") }

    /// Beside the hero distance: "mi left". Arg: unit abbreviation.
    static func homeHeroDistanceLeft(_ unit: String) -> String {
        String(format: home("home.hero.distanceLeft"), unit)
    }
    /// Beside the hero distance: "mi over". Arg: unit abbreviation.
    static func homeHeroDistanceOver(_ unit: String) -> String {
        String(format: home("home.hero.distanceOver"), unit)
    }
    /// Beside the hero day count; the count itself is the hero.
    static func homeHeroDaysLeft(_ count: Int) -> String {
        home(count == 1 ? "home.hero.dayLeft" : "home.hero.daysLeft")
    }
    static func homeHeroDaysOver(_ count: Int) -> String {
        home(count == 1 ? "home.hero.dayOver" : "home.hero.daysOver")
    }
    static func homeHeroDaysToExpiry(_ count: Int) -> String {
        home(count == 1 ? "home.hero.dayToExpiry" : "home.hero.daysToExpiry")
    }
    /// Hero figure read aloud: "12 days left". Args: number, qualifier.
    static func homeSpokenFigure(_ value: String, _ qualifier: String) -> String {
        String(format: home("home.spokenFigure"), value, qualifier)
    }
    /// VoiceOver value for the card. Args: status, hero phrase, due line.
    static func homeNextUpAccessibility(_ status: String, _ hero: String, _ dueLine: String) -> String {
        String(format: home("home.nextUp.accessibility"), status, hero, dueLine)
    }
    /// "Due 32,500 mi" or "Due Jul 4".
    static func homeDue(_ value: String) -> String {
        String(format: home("home.due"), value)
    }
    /// "Due 32,500 mi or Jul 4".
    static func homeDueMileageOrDate(_ mileage: String, _ date: String) -> String {
        String(format: home("home.dueMileageOrDate"), mileage, date)
    }
    /// Marbete due line: "Expires September 2026".
    static func homeExpires(_ monthYear: String) -> String {
        String(format: home("home.expires"), monthYear)
    }

    // MARK: - Marbete renewal

    static var homeMarbeteRenewTitle: String { home("home.marbete.renewTitle") }
    static func homeMarbeteRenewConfirm(_ monthYear: String) -> String {
        String(format: home("home.marbete.renewConfirm"), monthYear)
    }
    static func homeMarbeteRenewedToast(_ monthYear: String) -> String {
        String(format: home("home.marbete.renewedToast"), monthYear)
    }

    // MARK: - Vehicle band

    /// Stale-odometer tag: "16 d old".
    static func homeOdometerDaysOld(_ days: Int) -> String {
        String(format: home("home.odometer.daysOld"), days)
    }
    /// Stale-odometer tag when the reading was never dated.
    static var homeOdometerUpdate: String { home("home.odometer.update") }

    // MARK: - Suggestions

    static var homeSuggestions: String { home("home.suggestions") }
    static var homeSuggestionsEmpty: String { home("home.suggestions.empty") }
    static func homeSuggestionClusterTitle(_ count: Int) -> String {
        String(format: home("home.suggestion.clusterTitle"), count)
    }
    /// Args: joined service names, mileage window.
    static func homeSuggestionClusterDetail(_ names: String, _ window: String) -> String {
        String(format: home("home.suggestion.clusterDetail"), names, window)
    }
    static var homeSuggestionReviewVisit: String { home("home.suggestion.reviewVisit") }
    static var homeSuggestionNotNow: String { home("home.suggestion.notNow") }
    static var homeSuggestionSchedule: String { home("home.suggestion.schedule") }
    static var homeSuggestionNotThisYear: String { home("home.suggestion.notThisYear") }
    static var homeSuggestionNeverShow: String { home("home.suggestion.neverShow") }

    // MARK: - Sparse sections

    static var homeUpcomingEmpty: String { home("home.upcoming.empty") }
    static var homeRecentEmpty: String { home("home.recent.empty") }

    // MARK: - No vehicle

    static var homeEmptyTitle: String { home("home.empty.title") }
    static var homeEmptyMessage: String { home("home.empty.message") }
    static var homeEmptyAddVehicle: String { home("home.empty.addVehicle") }
    static var homeSyncingTitle: String { home("home.syncing.title") }
    static var homeSyncingMessage: String { home("home.syncing.message") }
}
