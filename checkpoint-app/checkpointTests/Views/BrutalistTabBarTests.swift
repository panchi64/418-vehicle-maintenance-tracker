//
//  BrutalistTabBarTests.swift
//  checkpointTests
//
//  Tests for BrutalistTabBar custom tab bar component
//

import XCTest
import SwiftUI
@testable import checkpoint

final class BrutalistTabBarTests: XCTestCase {

    // MARK: - Tab Selection Tests

    func testTabSelection_InitialState() {
        // Given
        var selectedTab = AppState.Tab.home

        // Then
        XCTAssertEqual(selectedTab, .home)
    }

    func testTabSelection_CanChangeToServices() {
        // Given
        var selectedTab = AppState.Tab.home

        // When
        selectedTab = .services

        // Then
        XCTAssertEqual(selectedTab, .services)
    }

    func testTabSelection_CanChangeToCosts() {
        // Given
        var selectedTab = AppState.Tab.home

        // When
        selectedTab = .costs

        // Then
        XCTAssertEqual(selectedTab, .costs)
    }

    func testTabSelection_CanChangeBackToHome() {
        // Given
        var selectedTab = AppState.Tab.services

        // When
        selectedTab = .home

        // Then
        XCTAssertEqual(selectedTab, .home)
    }

    // MARK: - Tab Properties Tests

    func testHomeTab_HasCorrectProperties() {
        // Given
        let tab = AppState.Tab.home

        // Then
        XCTAssertEqual(tab.title, "HOME")
        XCTAssertEqual(tab.icon, "house.fill")
        XCTAssertEqual(tab.rawValue, "home")
    }

    func testServicesTab_HasCorrectProperties() {
        // Given
        let tab = AppState.Tab.services

        // Then
        XCTAssertEqual(tab.title, "SERVICES")
        XCTAssertEqual(tab.icon, "wrench.and.screwdriver.fill")
        XCTAssertEqual(tab.rawValue, "services")
    }

    func testCostsTab_HasCorrectProperties() {
        // Given
        let tab = AppState.Tab.costs

        // Then
        XCTAssertEqual(tab.title, "COSTS")
        XCTAssertEqual(tab.icon, "dollarsign.circle.fill")
        XCTAssertEqual(tab.rawValue, "costs")
    }

    // MARK: - All Tabs Tests

    func testAllTabs_ArePresent() {
        // Given
        let allTabs = AppState.Tab.allCases

        // Then
        XCTAssertEqual(allTabs.count, 3)
        XCTAssertEqual(allTabs[0], .home)
        XCTAssertEqual(allTabs[1], .services)
        XCTAssertEqual(allTabs[2], .costs)
    }

    func testAllTabs_HaveUniqueRawValues() {
        // Given
        let allTabs = AppState.Tab.allCases
        let rawValues = allTabs.map { $0.rawValue }

        // Then
        let uniqueRawValues = Set(rawValues)
        XCTAssertEqual(rawValues.count, uniqueRawValues.count, "All tabs should have unique raw values")
    }

    func testAllTabs_HaveUniqueTitles() {
        // Given
        let allTabs = AppState.Tab.allCases
        let titles = allTabs.map { $0.title }

        // Then
        let uniqueTitles = Set(titles)
        XCTAssertEqual(titles.count, uniqueTitles.count, "All tabs should have unique titles")
    }

    func testAllTabs_HaveUniqueIcons() {
        // Given
        let allTabs = AppState.Tab.allCases
        let icons = allTabs.map { $0.icon }

        // Then
        let uniqueIcons = Set(icons)
        XCTAssertEqual(icons.count, uniqueIcons.count, "All tabs should have unique icons")
    }
}
