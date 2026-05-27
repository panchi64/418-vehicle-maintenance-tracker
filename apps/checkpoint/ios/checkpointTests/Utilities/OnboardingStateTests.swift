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

    func testAdvanceTour_pastLastStep_goesToTourRecap() {
        let state = OnboardingState()
        state.startTour()
        state.advanceTour() // → tour(step: 1)
        state.advanceTour() // → tourTransition(toStep: 2)
        state.resolveTransition() // → tour(step: 2)
        state.advanceTour() // → tourTransition(toStep: 3)
        state.resolveTransition() // → tour(step: 3)
        state.advanceTour() // → tourRecap
        XCTAssertEqual(state.currentPhase, .tourRecap)
    }

    func testAdvanceTour_fromTourRecap_isNoOp() {
        // .tourRecap exits via finishTour(), not advanceTour().
        let state = OnboardingState()
        state.startTour()
        state.advanceTour()
        state.advanceTour()
        state.resolveTransition()
        state.advanceTour()
        state.resolveTransition()
        state.advanceTour() // → tourRecap
        state.advanceTour() // should stay on tourRecap
        XCTAssertEqual(state.currentPhase, .tourRecap)
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

    // MARK: - Back navigation

    func testGoBackTour_fromMidTour_rewindsOneStep() {
        let state = OnboardingState()
        state.startTour()
        state.advanceTour() // → tour(step: 1)
        state.goBackTour()
        XCTAssertEqual(state.currentPhase, .tour(step: 0))
    }

    func testGoBackTour_fromTourStep0_noOp() {
        let state = OnboardingState()
        state.startTour()
        state.goBackTour()
        XCTAssertEqual(state.currentPhase, .tour(step: 0))
    }

    func testGoBackTour_fromTourRecap_returnsToLastSpotlight() {
        let state = OnboardingState()
        state.currentPhase = .tourRecap
        state.goBackTour()
        XCTAssertEqual(state.currentPhase, .tour(step: TourStep.lastIndex))
    }

    func testGoBackTour_fromTourTransition_noOp() {
        // The transition card has no Back affordance; goBackTour from there
        // is a defensive no-op rather than an unexpected rewind.
        let state = OnboardingState()
        state.currentPhase = .tourTransition(toStep: 2)
        state.goBackTour()
        XCTAssertEqual(state.currentPhase, .tourTransition(toStep: 2))
    }

    // MARK: - Replay

    func testReplayTour_resetsCompletedFlagAndGoesToTourStep0() {
        UserDefaults.standard.set(true, forKey: completedKey)
        let state = OnboardingState()
        state.seenTourSteps = [0, 1, 2, 3]
        state.replayTour()
        XCTAssertEqual(state.currentPhase, .tour(step: 0))
        XCTAssertFalse(OnboardingState.hasCompletedOnboarding)
        XCTAssertTrue(state.seenTourSteps.isEmpty)
    }

    func testReplayOnboarding_resetsCompletedFlagAndGoesToIntro() {
        UserDefaults.standard.set(true, forKey: completedKey)
        let state = OnboardingState()
        state.seenTourSteps = [0, 1]
        state.replayOnboarding()
        XCTAssertEqual(state.currentPhase, .intro)
        XCTAssertFalse(OnboardingState.hasCompletedOnboarding)
        XCTAssertTrue(state.seenTourSteps.isEmpty)
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

    func testIsTour_excludesTourRecap() {
        XCTAssertFalse(OnboardingPhase.tourRecap.isTour)
    }

    func testIsTour_introPhase_returnsFalse() {
        XCTAssertFalse(OnboardingPhase.intro.isTour)
    }

    func testIsTourRecap_recapPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.tourRecap.isTourRecap)
    }

    func testIsTourRecap_tourPhase_returnsFalse() {
        XCTAssertFalse(OnboardingPhase.tour(step: 0).isTourRecap)
    }

    func testIsActiveOnboarding_completedPhase_returnsFalse() {
        XCTAssertFalse(OnboardingPhase.completed.isActiveOnboarding)
    }

    func testIsActiveOnboarding_recapPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.tourRecap.isActiveOnboarding)
    }

    func testIsActiveOnboarding_tourPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.tour(step: 0).isActiveOnboarding)
    }

    func testIsActiveOnboarding_introPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.intro.isActiveOnboarding)
    }

    func testTourStep_tourPhase_returnsStep() {
        XCTAssertEqual(OnboardingPhase.tour(step: 2).tourStep, 2)
    }

    func testTourStep_transitionPhase_returnsToStep() {
        XCTAssertEqual(OnboardingPhase.tourTransition(toStep: 3).tourStep, 3)
    }

    func testTourStep_nonTourPhase_returnsNil() {
        XCTAssertNil(OnboardingPhase.intro.tourStep)
        XCTAssertNil(OnboardingPhase.tourRecap.tourStep)
    }

    // MARK: - Sample Vehicle IDs

    func testSampleVehicleIDs_defaultEmpty() {
        let state = OnboardingState()
        XCTAssertTrue(state.sampleVehicleIDs.isEmpty)
    }

    // MARK: - Seen Tour Steps

    func testSeenTourSteps_defaultEmpty() {
        let state = OnboardingState()
        XCTAssertTrue(state.seenTourSteps.isEmpty)
    }
}
