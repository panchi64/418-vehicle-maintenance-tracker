//
//  TourStep.swift
//  checkpoint
//
//  Single source of truth for the onboarding tour. Each step bundles the
//  spotlight target, the tab it lives on, the localized title/body, and
//  (when entering this step requires a tab change) the transition card's
//  section label. OnboardingState, ContentView, OnboardingTourOverlay, and
//  OnboardingTourTransitionCard all read from this table — adding a step
//  is a single append.
//

import Foundation

struct TourStep {
    let target: TourTargetID
    let tab: Tab
    let title: () -> String
    let body: () -> String
    /// Section label shown on the interstitial card when this step lives on
    /// a different tab than its predecessor. Nil for steps that don't need
    /// a transition (the first step, and any step on the same tab as the
    /// previous one).
    let transitionLabel: (() -> String)?

    static let all: [TourStep] = [
        TourStep(
            target: .dashboardSpecs,
            tab: .home,
            title: { L10n.onboardingTourDashboardTitle },
            body: { L10n.onboardingTourDashboardBody },
            transitionLabel: nil
        ),
        TourStep(
            target: .vehicleHeader,
            tab: .home,
            title: { L10n.onboardingTourVehicleTitle },
            body: { L10n.onboardingTourVehicleBody },
            transitionLabel: nil
        ),
        TourStep(
            target: .servicesSearch,
            tab: .services,
            title: { L10n.onboardingTourServicesTitle },
            body: { L10n.onboardingTourServicesBody },
            transitionLabel: { L10n.onboardingTransitionServices }
        ),
        TourStep(
            target: .costsHeadline,
            tab: .costs,
            title: { L10n.onboardingTourCostsTitle },
            body: { L10n.onboardingTourCostsBody },
            transitionLabel: { L10n.onboardingTransitionCosts }
        )
    ]

    /// Returns the step at the given index, or nil if out of range.
    static func at(_ index: Int) -> TourStep? {
        all.indices.contains(index) ? all[index] : nil
    }

    /// Returns the last valid step index.
    static var lastIndex: Int { all.count - 1 }
}
