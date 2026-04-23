//
//  OnboardingStateTests.swift
//  checkpointTests
//
//  Tests for OnboardingState phase transitions and persistence
//

import XCTest
@testable import checkpoint

@MainActor
final class OnboardingStateTests: XCTestCase {

    private let completedKey = "hasCompletedOnboarding"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: completedKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: completedKey)
        super.tearDown()
    }

    // MARK: - Initialization

    func testInit_freshInstall_startsAtIntro() {
        let state = OnboardingState()
        XCTAssertEqual(state.currentPhase, .intro)
    }

    func testInit_completedOnboarding_startsAtCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
        let state = OnboardingState()
        XCTAssertEqual(state.currentPhase, .completed)
    }

    // MARK: - Phase Transitions

    func testStartTour_setsPhaseToTourStep0() {
        let state = OnboardingState()
        state.startTour()
        XCTAssertEqual(state.currentPhase, .tour(step: 0))
    }

    func testAdvanceTour_sameTab_noTransition() {
        // Step 0 → 1: both on Home tab, no transition needed
        let state = OnboardingState()
        state.startTour()
        state.advanceTour()
        XCTAssertEqual(state.currentPhase, .tour(step: 1))
    }

    func testAdvanceTour_tabChange_insertsTransition() {
        // Step 1 → 2: Home → Services, should insert transition
        let state = OnboardingState()
        state.startTour()
        state.advanceTour() // → tour(step: 1)
        state.advanceTour() // → tourTransition(toStep: 2)
        XCTAssertEqual(state.currentPhase, .tourTransition(toStep: 2))
    }

    func testAdvanceTour_step2To3_insertsTransition() {
        // Step 2 → 3: Services → Costs, should insert transition
        let state = OnboardingState()
        state.startTour()
        state.advanceTour() // → tour(step: 1)
        state.advanceTour() // → tourTransition(toStep: 2)
        state.resolveTransition() // → tour(step: 2)
        state.advanceTour() // → tourTransition(toStep: 3)
        XCTAssertEqual(state.currentPhase, .tourTransition(toStep: 3))
    }

    func testAdvanceTour_pastStep3_goesToGetStarted() {
        let state = OnboardingState()
        state.startTour()
        state.advanceTour() // → tour(step: 1)
        state.advanceTour() // → tourTransition(toStep: 2)
        state.resolveTransition() // → tour(step: 2)
        state.advanceTour() // → tourTransition(toStep: 3)
        state.resolveTransition() // → tour(step: 3)
        state.advanceTour() // → getStarted
        XCTAssertEqual(state.currentPhase, .getStarted)
    }

    func testResolveTransition_movesToTourStep() {
        let state = OnboardingState()
        state.startTour()
        state.advanceTour() // → tour(step: 1)
        state.advanceTour() // → tourTransition(toStep: 2)
        state.resolveTransition()
        XCTAssertEqual(state.currentPhase, .tour(step: 2))
    }

    func testResolveTransition_noOp_whenNotTransition() {
        let state = OnboardingState()
        state.startTour() // → tour(step: 0)
        state.resolveTransition() // should be a no-op
        XCTAssertEqual(state.currentPhase, .tour(step: 0))
    }

    func testFinishTour_goesToGetStarted() {
        let state = OnboardingState()
        state.startTour()
        state.finishTour()
        XCTAssertEqual(state.currentPhase, .getStarted)
    }

    func testComplete_setsCompletedPhaseAndPersists() {
        let state = OnboardingState()
        state.complete()
        XCTAssertEqual(state.currentPhase, .completed)
        XCTAssertTrue(OnboardingState.hasCompletedOnboarding)
    }

    // MARK: - Phase Properties

    func testIsTour_tourPhase_returnsTrue() {
        let phase = OnboardingPhase.tour(step: 2)
        XCTAssertTrue(phase.isTour)
    }

    func testIsTour_includesTransition() {
        let phase = OnboardingPhase.tourTransition(toStep: 2)
        XCTAssertTrue(phase.isTour)
    }

    func testIsTour_introPhase_returnsFalse() {
        XCTAssertFalse(OnboardingPhase.intro.isTour)
    }

    func testIsTourTransition_transitionPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.tourTransition(toStep: 2).isTourTransition)
    }

    func testIsTourTransition_tourPhase_returnsFalse() {
        XCTAssertFalse(OnboardingPhase.tour(step: 2).isTourTransition)
    }

    func testIsTourTransition_introPhase_returnsFalse() {
        XCTAssertFalse(OnboardingPhase.intro.isTourTransition)
    }

    func testIsTourOrGetStarted_tourPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.tour(step: 0).isTourOrGetStarted)
    }

    func testIsTourOrGetStarted_transitionPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.tourTransition(toStep: 2).isTourOrGetStarted)
    }

    func testIsTourOrGetStarted_getStartedPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.getStarted.isTourOrGetStarted)
    }

    func testIsTourOrGetStarted_completedPhase_returnsFalse() {
        XCTAssertFalse(OnboardingPhase.completed.isTourOrGetStarted)
    }

    func testTourStep_tourPhase_returnsStep() {
        XCTAssertEqual(OnboardingPhase.tour(step: 2).tourStep, 2)
    }

    func testTourStep_transitionPhase_returnsToStep() {
        XCTAssertEqual(OnboardingPhase.tourTransition(toStep: 3).tourStep, 3)
    }

    func testTourStep_nonTourPhase_returnsNil() {
        XCTAssertNil(OnboardingPhase.intro.tourStep)
    }

    // MARK: - Sample Vehicle IDs

    func testSampleVehicleIDs_defaultEmpty() {
        let state = OnboardingState()
        XCTAssertTrue(state.sampleVehicleIDs.isEmpty)
    }
}
