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
        currentPhase = .tour(step: 0)
    }

    func advanceTour() {
        guard case .tour(let step) = currentPhase else { return }
        let nextStep = step + 1
        if nextStep > 3 {
            currentPhase = .getStarted
        } else if tabForStep(nextStep) != tabForStep(step) {
            currentPhase = .tourTransition(toStep: nextStep)
        } else {
            currentPhase = .tour(step: nextStep)
        }
    }

    func resolveTransition() {
        guard case .tourTransition(let toStep) = currentPhase else { return }
        currentPhase = .tour(step: toStep)
    }

    func finishTour() {
        currentPhase = .getStarted
    }

    func complete() {
        Self.hasCompletedOnboarding = true
        currentPhase = .completed
    }

    // MARK: - Helpers

    /// Maps tour steps to tab indices: 0,1 → Home (0); 2 → Services (1); 3 → Costs (2)
    private func tabForStep(_ step: Int) -> Int {
        switch step {
        case 0, 1: return 0
        case 2: return 1
        case 3: return 2
        default: return 0
        }
    }
}
