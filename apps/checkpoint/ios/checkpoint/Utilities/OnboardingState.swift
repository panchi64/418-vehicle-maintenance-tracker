//
//  OnboardingState.swift
//  checkpoint
//
//  State machine for the onboarding flow with persistence.
//
//  Four short steps: the welcome page, then one spotlight per tab. The
//  between-tab transition cards and the closing recap card are gone — they
//  narrated what the spotlight cards already say. Every step can be skipped.
//

import SwiftUI

enum OnboardingPhase: Equatable {
    case intro
    case tour(step: Int)
    case getStarted
    case completed

    /// True for the anchored, spotlight-driven steps.
    var isTour: Bool {
        if case .tour = self { return true }
        return false
    }

    /// True for every phase EXCEPT `.completed`. Used to gate UI gestures
    /// (e.g. tab swipes) and app-initiated prompts (tip, notifications) that
    /// must not fire while any onboarding surface is on screen.
    var isActiveOnboarding: Bool {
        self != .completed
    }

    var tourStep: Int? {
        if case .tour(let step) = self { return step }
        return nil
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

    /// Next spotlight, or — past the last one — the hand-off to adding a
    /// vehicle. The tab follows via ContentView's phase `onChange`.
    func advanceTour() {
        guard case .tour(let step) = currentPhase else { return }
        let next = step + 1
        animate {
            currentPhase = TourStep.at(next) != nil ? .tour(step: next) : .getStarted
        }
    }

    /// Rewinds a single step in the tour.
    func goBackTour() {
        guard case .tour(let step) = currentPhase, step > 0 else { return }
        animate { currentPhase = .tour(step: step - 1) }
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
        animate { currentPhase = .tour(step: 0) }
    }

    /// Replays the entire onboarding flow (intro + tour). Used by the
    /// DEBUG section; the user-facing Settings row goes through
    /// `replayTour()` to skip the preferences re-prompt.
    func replayOnboarding() {
        Self.hasCompletedOnboarding = false
        animate { currentPhase = .intro }
    }

    // MARK: - Helpers

    /// Tab that hosts the given tour step. Falls back to `.home` for out-of-range
    /// indices (defensive — callers should pass valid indices).
    func tab(forStep step: Int) -> Tab {
        TourStep.at(step)?.tab ?? .home
    }

    /// Wraps a phase mutation in an animation so attached `.transition(...)`
    /// modifiers on the overlay actually fire.
    private func animate(_ change: () -> Void) {
        withAnimation(.easeOut(duration: Theme.animationMedium), change)
    }
}
