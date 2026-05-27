//
//  OnboardingState.swift
//  checkpoint
//
//  State machine for the onboarding flow with persistence
//

import SwiftUI

enum OnboardingPhase: Equatable {
    case intro
    case tour(step: Int)
    case tourTransition(toStep: Int)
    case getStarted
    case completed

    var isTour: Bool {
        switch self {
        case .tour, .tourTransition: return true
        default: return false
        }
    }

    var isTourTransition: Bool {
        if case .tourTransition = self { return true }
        return false
    }

    var isTourOrGetStarted: Bool {
        switch self {
        case .tour, .tourTransition, .getStarted: return true
        default: return false
        }
    }

    var tourStep: Int? {
        switch self {
        case .tour(let step): return step
        case .tourTransition(let toStep): return toStep
        default: return nil
        }
    }
}

@Observable
@MainActor
final class OnboardingState {
    // MARK: - Persistence

    private static let completedKey = "hasCompletedOnboarding"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    // MARK: - State

    var currentPhase: OnboardingPhase

    /// IDs of sample vehicles created during tour so we can clean them up
    var sampleVehicleIDs: [UUID] = []

    // MARK: - Init

    init() {
        currentPhase = Self.hasCompletedOnboarding ? .completed : .intro
    }

    // MARK: - Phase Transitions

    func startTour() {
        animate { currentPhase = .tour(step: 0) }
    }

    func advanceTour() {
        guard case .tour(let step) = currentPhase else { return }
        let nextStep = step + 1
        let newPhase: OnboardingPhase

        if let next = TourStep.at(nextStep), let current = TourStep.at(step) {
            newPhase = next.tab != current.tab
                ? .tourTransition(toStep: nextStep)
                : .tour(step: nextStep)
        } else {
            newPhase = .getStarted
        }

        animate { currentPhase = newPhase }
    }

    func resolveTransition() {
        guard case .tourTransition(let toStep) = currentPhase else { return }
        animate { currentPhase = .tour(step: toStep) }
    }

    func finishTour() {
        animate { currentPhase = .getStarted }
    }

    func complete() {
        Self.hasCompletedOnboarding = true
        animate { currentPhase = .completed }
    }

    // MARK: - Helpers

    /// Tab that hosts the given tour step. Falls back to `.home` for out-of-range
    /// indices (defensive — callers should pass valid indices).
    func tab(forStep step: Int) -> Tab {
        TourStep.at(step)?.tab ?? .home
    }

    /// Wraps a phase mutation in an animation so attached `.transition(...)`
    /// modifiers on the overlay/transition card actually fire.
    private func animate(_ change: () -> Void) {
        withAnimation(.easeOut(duration: Theme.animationMedium), change)
    }
}
