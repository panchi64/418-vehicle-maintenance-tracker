//
//  AppStateTests.swift
//  checkpointTests
//
//  Tests for AppState, the shared state management for tab navigation
//

import XCTest
import SwiftData
@testable import checkpoint

final class AppStateTests: XCTestCase {

    // MARK: - Tab Enum Tests (No MainActor needed)

    func testTab_AllCases() {
        // Then
        XCTAssertEqual(Tab.allCases.count, 3)
        XCTAssertTrue(Tab.allCases.contains(.home))
        XCTAssertTrue(Tab.allCases.contains(.services))
        XCTAssertTrue(Tab.allCases.contains(.costs))
    }

    func testTab_Titles() {
        // Then
        XCTAssertEqual(Tab.home.title, "HOME")
        XCTAssertEqual(Tab.services.title, "SERVICES")
        XCTAssertEqual(Tab.costs.title, "COSTS")
    }

    func testTab_Icons() {
        // Then
        XCTAssertEqual(Tab.home.icon, "house.fill")
        XCTAssertEqual(Tab.services.icon, "wrench.and.screwdriver.fill")
        XCTAssertEqual(Tab.costs.icon, "dollarsign.circle.fill")
    }

    // MARK: - Initialization Tests

    @MainActor
    func testAppState_DefaultInitialization() async {
        // Given/When
        let appState = AppState()

        // Then
        XCTAssertNil(appState.selectedVehicle)
        XCTAssertEqual(appState.selectedTab, .home)
        XCTAssertFalse(appState.showVehiclePicker)
        XCTAssertFalse(appState.showAddVehicle)
        XCTAssertFalse(appState.showAddService)
        XCTAssertFalse(appState.showEditVehicle)
        XCTAssertNil(appState.selectedService)
        XCTAssertNil(appState.selectedServiceLog)
    }

    // MARK: - Selected Service Log Tests

    @MainActor
    func testSelectedServiceLog_DefaultsToNil() async {
        // Given/When
        let appState = AppState()

        // Then
        XCTAssertNil(appState.selectedServiceLog)
    }

    @MainActor
    func testSelectedServiceLog_CanBeSet() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self, ServicePreset.self,
            configurations: config
        )
        let modelContext = modelContainer.mainContext

        let appState = AppState()
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000,
            cost: 45.99
        )
        modelContext.insert(log)

        // When
        appState.selectedServiceLog = log

        // Then
        XCTAssertNotNil(appState.selectedServiceLog)
        XCTAssertEqual(appState.selectedServiceLog?.mileageAtService, 32000)

        // Cleanup
        appState.selectedServiceLog = nil
    }

    @MainActor
    func testSelectedServiceLog_CanBeCleared() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self, ServicePreset.self,
            configurations: config
        )
        let modelContext = modelContainer.mainContext

        let appState = AppState()
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000
        )
        modelContext.insert(log)
        appState.selectedServiceLog = log

        // When
        appState.selectedServiceLog = nil

        // Then
        XCTAssertNil(appState.selectedServiceLog)
    }

    // MARK: - Sheet State Tests

    @MainActor
    func testSheetStates_CanBeToggled() async {
        // Given
        let appState = AppState()

        // When/Then - Vehicle Picker
        appState.showVehiclePicker = true
        XCTAssertTrue(appState.showVehiclePicker)
        appState.showVehiclePicker = false
        XCTAssertFalse(appState.showVehiclePicker)

        // When/Then - Add Vehicle
        appState.showAddVehicle = true
        XCTAssertTrue(appState.showAddVehicle)
        appState.showAddVehicle = false
        XCTAssertFalse(appState.showAddVehicle)

        // When/Then - Add Service
        appState.showAddService = true
        XCTAssertTrue(appState.showAddService)
        appState.showAddService = false
        XCTAssertFalse(appState.showAddService)

        // When/Then - Edit Vehicle
        appState.showEditVehicle = true
        XCTAssertTrue(appState.showEditVehicle)
        appState.showEditVehicle = false
        XCTAssertFalse(appState.showEditVehicle)
    }

    // MARK: - Vehicle Selection Tests

    @MainActor
    func testSelectedVehicle_CanBeSet() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self, ServicePreset.self,
            configurations: config
        )
        let modelContext = modelContainer.mainContext

        let appState = AppState()
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022
        )
        modelContext.insert(vehicle)

        // When
        appState.selectedVehicle = vehicle

        // Then
        XCTAssertNotNil(appState.selectedVehicle)
        XCTAssertEqual(appState.selectedVehicle?.name, "Test Car")

        // Cleanup: clear reference before test ends to avoid deallocation crash
        appState.selectedVehicle = nil
    }

    @MainActor
    func testSelectedVehicle_CanBeCleared() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self, ServicePreset.self,
            configurations: config
        )
        let modelContext = modelContainer.mainContext

        let appState = AppState()
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022
        )
        modelContext.insert(vehicle)
        appState.selectedVehicle = vehicle

        // When
        appState.selectedVehicle = nil

        // Then
        XCTAssertNil(appState.selectedVehicle)
    }

    // MARK: - Tab Selection Tests

    @MainActor
    func testSelectedTab_CanBeChanged() async {
        // Given
        let appState = AppState()

        // When/Then
        appState.selectedTab = .services
        XCTAssertEqual(appState.selectedTab, .services)

        appState.selectedTab = .costs
        XCTAssertEqual(appState.selectedTab, .costs)

        appState.selectedTab = .home
        XCTAssertEqual(appState.selectedTab, .home)
    }

    // MARK: - Recall Ordering Tests

    func testRecallInfo_SortedNewestFirst_OrdersByReportDateWithUndatedLast() {
        let older = RecallInfo(
            campaignNumber: "23V456", component: "FUEL", summary: "", consequence: "", remedy: "",
            reportDate: "06/20/2023", parkIt: false, parkOutside: false
        )
        let newest = RecallInfo(
            campaignNumber: "24V789", component: "STEERING", summary: "", consequence: "", remedy: "",
            reportDate: "03/10/2024", parkIt: false, parkOutside: false
        )
        let middle = RecallInfo(
            campaignNumber: "24V123", component: "AIR BAGS", summary: "", consequence: "", remedy: "",
            reportDate: "01/15/2024", parkIt: false, parkOutside: false
        )
        let undated = RecallInfo(
            campaignNumber: "00V000", component: "UNKNOWN", summary: "", consequence: "", remedy: "",
            reportDate: "", parkIt: false, parkOutside: false
        )

        let ordered = [older, undated, newest, middle].sortedNewestFirst()

        XCTAssertEqual(ordered.map(\.campaignNumber), ["24V789", "24V123", "23V456", "00V000"])
    }

    /// 2006 Honda Element regression: NHTSA's API mixes MM/dd/yyyy and dd/MM/yyyy
    /// in the same response. Both must parse so older dd/MM dates don't sink past
    /// MM/dd-parseable entries.
    func testRecallInfo_SortedNewestFirst_HandlesMixedNHTSADateFormats() {
        let raw: [(String, String)] = [
            ("19V182000", "06/03/2019"),
            ("19V499000", "27/06/2019"),
            ("19V501000", "27/06/2019"),
            ("06V270000", "26/07/2006"),
            ("18V268000", "26/04/2018"),
            ("17V029000", "10/01/2017"),
            ("15V320000", "28/05/2015"),
            ("16V344000", "23/05/2016"),
            ("11V395000", "04/08/2011"),
            ("09E012000", "07/04/2009"),
            ("09E025000", "11/05/2009"),
        ]
        let recalls = raw.map { campaign, date in
            RecallInfo(
                campaignNumber: campaign, component: "", summary: "", consequence: "", remedy: "",
                reportDate: date, parkIt: false, parkOutside: false
            )
        }

        let ordered = recalls.sortedNewestFirst()

        XCTAssertEqual(ordered.first?.campaignNumber, "19V499000",
                       "Newest dd/MM/yyyy entry must sort first")
        XCTAssertEqual(ordered.last?.campaignNumber, "06V270000",
                       "Oldest entry (2006) must sort last")
        for (lhs, rhs) in zip(ordered, ordered.dropFirst()) {
            let lhsDate = lhs.reportDateParsed ?? .distantPast
            let rhsDate = rhs.reportDateParsed ?? .distantPast
            XCTAssertGreaterThanOrEqual(lhsDate, rhsDate,
                "\(lhs.campaignNumber) (\(lhs.reportDate)) must not precede \(rhs.campaignNumber) (\(rhs.reportDate))")
        }
    }
}
