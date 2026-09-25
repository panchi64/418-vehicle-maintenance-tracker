//
//  TourStep.swift
//  checkpoint
//
//  Single source of truth for the onboarding tour. Each step bundles the
//  spotlight target, the tab it lives on, and the localized title/body.
//  OnboardingState, ContentView and OnboardingTourOverlay all read from this
//  table — adding a step is a single append.
//
//  One step per tab. The tour used to spend seven screens (four spotlights,
//  two between-tab cards, a recap) saying what three do; with the welcome
//  page the whole thing is four short steps. The card's `Next: Services`
//  label already narrates a tab change, so no interstitial is needed.
//

import Foundation

struct TourStep {
    let target: TourTargetID
    let tab: Tab
    let title: () -> String
    let body: () -> String

    static let all: [TourStep] = [
        TourStep(
            // "The most urgent item surfaces first" — which is Next Up. The
            // body also points at the title menu (vehicle switcher), which is
            // system chrome with no frame to spotlight.
            target: .homeNextUp,
            tab: .home,
            title: { L10n.onboardingTourDashboardTitle },
            body: { L10n.onboardingTourDashboardBody }
        ),
        TourStep(
            // Search is the system field, which exposes no frame; the first
            // status group's header stands in for the grouped list.
            target: .servicesStatusGroup,
            tab: .services,
            title: { L10n.onboardingTourServicesTitle },
            body: { L10n.onboardingTourServicesBody }
        ),
        TourStep(
            target: .costsHeadline,
            tab: .costs,
            title: { L10n.onboardingTourCostsTitle },
            body: { L10n.onboardingTourCostsBody }
        )
    ]

    /// Returns the step at the given index, or nil if out of range.
    static func at(_ index: Int) -> TourStep? {
        all.indices.contains(index) ? all[index] : nil
    }

    /// Returns the last valid step index.
    static var lastIndex: Int { all.count - 1 }
}
