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
    /// Final tour beat — a centered recap card with no spotlight, shown
    /// after the last anchored step. Closes the tour by tying the three
    /// tabs into a single mental model before handing off to .getStarted.
    case tourRecap
    case getStarted
    case completed

    /// True for the anchored, spotlight-driven steps. The recap is a
    /// separate non-anchored beat, so it is NOT a tour phase by this
    /// definition — render it through its own branch.
    var isTour: Bool {
        switch self {
        case .tour, .tourTransition: return true
        default: return false
        }
    }

    var isTourRecap: Bool {
        if case .tourRecap = self { return true }
        return false
    }

    /// True for every phase EXCEPT `.completed`. Used to gate UI gestures
    /// (e.g. tab swipes) that should not fire while any onboarding surface
    /// is on screen.
    var isActiveOnboarding: Bool {
        self != .completed
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

    /// Tour steps whose Skip cooldown has already elapsed once. Used to
    /// keep Skip immediately available when the user navigates Back to a
    /// step they have already glanced at — the cooldown's purpose
    /// (force-glance before bailing) is already satisfied for those.
    var seenTourSteps: Set<Int> = []

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
            // Past the last spotlight step — show the recap before handing
            // off to .getStarted.
            newPhase = .tourRecap
        }

        animate { currentPhase = newPhase }
    }

    /// Rewinds a single step in the tour. Back across a tab boundary is a
    /// direct rewind — the transition card only narrates forward motion;
    /// rewinding through it would feel like a stutter. The tab itself
    /// follows automatically via ContentView's `.onChange(of: currentPhase)`
    /// handler.
    func goBackTour() {
        switch currentPhase {
        case .tour(let step) where step > 0:
            animate { currentPhase = .tour(step: step - 1) }
        case .tourRecap:
            animate { currentPhase = .tour(step: TourStep.lastIndex) }
        default:
            return
        }
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

    /// Replays the tour from step 0, bypassing the intro (the user already
    /// went through preferences). Caller is responsible for seeding sample
    /// data first so the spotlight anchors resolve against something.
    func replayTour() {
        Self.hasCompletedOnboarding = false
        seenTourSteps = []
        animate { currentPhase = .tour(step: 0) }
    }

    /// Replays the entire onboarding flow (intro + tour). Used by the
    /// DEBUG section; the user-facing Settings row goes through
    /// `replayTour()` to skip the preferences re-prompt.
    func replayOnboarding() {
        Self.hasCompletedOnboarding = false
        seenTourSteps = []
        animate { currentPhase = .intro }
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
