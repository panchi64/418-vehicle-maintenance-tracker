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

    // MARK: - Length

    func testTour_isAtMostFourStepsWithWelcome() {
        // Welcome page + one spotlight per tab. The tour must stay short.
        XCTAssertLessThanOrEqual(TourStep.all.count + 1, 4)
    }

    func testTour_oneStepPerTab() {
        let tabs = TourStep.all.map(\.tab)
        XCTAssertEqual(tabs, [.home, .services, .costs])
    }

    // MARK: - Phase Transitions

    func testStartTour_setsPhaseToTourStep0() {
        let state = OnboardingState()
        state.startTour()
        XCTAssertEqual(state.currentPhase, .tour(step: 0))
    }

    func testAdvanceTour_crossingTabs_goesStraightToNextStep() {
        // No interstitial card between tabs.
        let state = OnboardingState()
        state.startTour()
        state.advanceTour()
        XCTAssertEqual(state.currentPhase, .tour(step: 1))
    }

    func testAdvanceTour_pastLastStep_goesToGetStarted() {
        let state = OnboardingState()
        state.startTour()
        for _ in 0...TourStep.lastIndex {
            state.advanceTour()
        }
        XCTAssertEqual(state.currentPhase, .getStarted)
    }

    func testAdvanceTour_outsideTour_isNoOp() {
        let state = OnboardingState()
        state.advanceTour()
        XCTAssertEqual(state.currentPhase, .intro)
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

    func testGoBackTour_fromGetStarted_noOp() {
        let state = OnboardingState()
        state.currentPhase = .getStarted
        state.goBackTour()
        XCTAssertEqual(state.currentPhase, .getStarted)
    }

    // MARK: - Replay

    func testReplayTour_resetsCompletedFlagAndGoesToTourStep0() {
        UserDefaults.standard.set(true, forKey: completedKey)
        let state = OnboardingState()
        state.replayTour()
        XCTAssertEqual(state.currentPhase, .tour(step: 0))
        XCTAssertFalse(OnboardingState.hasCompletedOnboarding)
    }

    func testReplayOnboarding_resetsCompletedFlagAndGoesToIntro() {
        UserDefaults.standard.set(true, forKey: completedKey)
        let state = OnboardingState()
        state.replayOnboarding()
        XCTAssertEqual(state.currentPhase, .intro)
        XCTAssertFalse(OnboardingState.hasCompletedOnboarding)
    }

    // MARK: - Phase Properties

    func testIsTour_tourPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.tour(step: 2).isTour)
    }

    func testIsTour_introAndGetStarted_returnFalse() {
        XCTAssertFalse(OnboardingPhase.intro.isTour)
        XCTAssertFalse(OnboardingPhase.getStarted.isTour)
    }

    func testIsActiveOnboarding_completedPhase_returnsFalse() {
        XCTAssertFalse(OnboardingPhase.completed.isActiveOnboarding)
    }

    func testIsActiveOnboarding_everyOtherPhase_returnsTrue() {
        XCTAssertTrue(OnboardingPhase.intro.isActiveOnboarding)
        XCTAssertTrue(OnboardingPhase.tour(step: 0).isActiveOnboarding)
        XCTAssertTrue(OnboardingPhase.getStarted.isActiveOnboarding)
    }

    func testTourStep_tourPhase_returnsStep() {
        XCTAssertEqual(OnboardingPhase.tour(step: 2).tourStep, 2)
    }

    func testTourStep_nonTourPhase_returnsNil() {
        XCTAssertNil(OnboardingPhase.intro.tourStep)
        XCTAssertNil(OnboardingPhase.getStarted.tourStep)
    }

    // MARK: - Sample Vehicle IDs

    func testSampleVehicleIDs_defaultEmpty() {
        let state = OnboardingState()
        XCTAssertTrue(state.sampleVehicleIDs.isEmpty)
    }
}
