//
//  AppStateTests.swift
//  checkpointTests
//
//  Tests for AppState: tab navigation, per-tab paths, and the root sheet router
//

import XCTest
import SwiftData
@testable import checkpoint

final class AppStateTests: XCTestCase {

    // MARK: - Tab Enum Tests (No MainActor needed)

    func testTab_AllCases_AreInTabBarOrder() {
        // Home leads: it is the default selection.
        XCTAssertEqual(Tab.allCases, [.home, .services, .costs])
    }

    func testTab_Titles_AreLocalized() {
        XCTAssertEqual(Tab.home.title, L10n.tabHome)
        XCTAssertEqual(Tab.services.title, L10n.tabServices)
        XCTAssertEqual(Tab.costs.title, L10n.tabCosts)
        XCTAssertFalse(Tab.home.title.isEmpty)
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
        XCTAssertNil(appState.activeSheet)
        XCTAssertNil(appState.presentedSheet)
        XCTAssertNil(appState.queuedSheet)
        XCTAssertTrue(appState.paths.isEmpty)
    }

    // MARK: - Navigation Path Tests

    @MainActor
    func testPush_AppendsToTheVisibleTabsStack() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self, ServicePreset.self,
            configurations: config
        )
        let log = ServiceLog(performedDate: .now, mileageAtService: 32000, cost: 45.99)
        modelContainer.mainContext.insert(log)

        let appState = AppState()
        appState.selectedTab = .costs

        appState.push(.serviceLog(log))

        XCTAssertEqual(appState.paths[.costs], [.serviceLog(log)])
        XCTAssertNil(appState.paths[.home])
    }

    @MainActor
    func testShowDetail_ClosesTheSheetAndPushes() async throws {
        let service = Service(name: "Oil Change")
        let appState = AppState()
        appState.present(.settings)
        appState.sheetDidAppear(.settings)

        appState.showDetail(.service(service))

        XCTAssertNil(appState.activeSheet)
        XCTAssertEqual(appState.paths[.home], [.service(service)])
    }

    @MainActor
    func testSelectVehicle_PopsEveryStack() async {
        let service = Service(name: "Oil Change")
        let appState = AppState()
        appState.paths[.services] = [.service(service)]

        appState.selectVehicle(Vehicle(name: "Other", make: "Honda", model: "Civic", year: 2020))

        XCTAssertTrue(appState.paths.isEmpty)
    }

    // MARK: - Sheet Router Tests

    @MainActor
    func testPresent_WithNothingOnScreen_PresentsImmediately() async {
        let appState = AppState()

        appState.present(.addService())

        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.addService().id)
        XCTAssertNil(appState.queuedSheet)
    }

    @MainActor
    func testPresent_WhileASheetIsOnScreen_WaitsForItsDismissal() async {
        // The "dismiss then present in the same tick" bug: the second sheet
        // must not be requested until the first has finished closing.
        let appState = AppState()
        appState.present(.vehiclePicker)
        appState.sheetDidAppear(.vehiclePicker)

        appState.present(.addVehicle)

        XCTAssertNil(appState.activeSheet)
        XCTAssertEqual(appState.queuedSheet?.id, ActiveSheet.addVehicle.id)

        let dismissed = appState.sheetDidDismiss()

        XCTAssertEqual(dismissed?.id, ActiveSheet.vehiclePicker.id)
        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.addVehicle.id)
        XCTAssertNil(appState.queuedSheet)
    }

    @MainActor
    func testPresentWhenIdle_DoesNotCloseTheSheetOnScreen() async {
        let appState = AppState()
        appState.present(.addService())
        appState.sheetDidAppear(.addService())

        appState.presentWhenIdle(.tipModal)

        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.addService().id)
        XCTAssertEqual(appState.queuedSheet?.id, ActiveSheet.tipModal.id)

        appState.activeSheet = nil
        appState.sheetDidDismiss()

        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.tipModal.id)
    }

    @MainActor
    func testDismissSheet_DropsTheQueue() async {
        let appState = AppState()
        appState.present(.settings)
        appState.sheetDidAppear(.settings)
        appState.present(.proPaywall)

        appState.dismissSheet()
        appState.sheetDidDismiss()

        XCTAssertNil(appState.activeSheet)
        XCTAssertNil(appState.queuedSheet)
    }

    @MainActor
    func testRequestAddVehicle_UnderTheLimit_PresentsAddVehicle() async {
        let appState = AppState()

        appState.requestAddVehicle(vehicleCount: 0)

        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.addVehicle.id)
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

    // MARK: - Container Swap Tests

    @MainActor
    func testPrepareForContainerSwap_ClearsRetainedModelReferences() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self, ServiceAttachment.self, ServicePreset.self, ServiceVisit.self,
            configurations: config
        )
        let modelContext = modelContainer.mainContext

        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022)
        let service = Service(name: "Oil Change")
        let log = ServiceLog(performedDate: .now, mileageAtService: 30_000)
        let visit = ServiceVisit(vehicle: vehicle, performedDate: .now, mileageAtVisit: 30_000)
        let doc = Document(data: Data(), fileName: "x.jpg", mimeType: "image/jpeg")
        modelContext.insert(vehicle)
        modelContext.insert(service)
        modelContext.insert(log)
        modelContext.insert(visit)
        modelContext.insert(doc)

        let appState = AppState()
        appState.selectedVehicle = vehicle
        appState.paths[.home] = [.service(service), .serviceLog(log)]
        appState.paths[.costs] = [.visit(visit)]
        appState.paths[.services] = [.document(doc)]
        let cluster = ServiceCluster(
            services: [service],
            anchorService: service,
            vehicle: vehicle,
            mileageWindow: 500,
            daysWindow: 30
        )
        appState.present(.clusterDetail(cluster))

        // When
        appState.prepareForContainerSwap()

        // Then — every SwiftData-backed reference is released
        XCTAssertNil(appState.selectedVehicle)
        XCTAssertTrue(appState.paths.isEmpty)
        XCTAssertNil(appState.activeSheet)
    }

    @MainActor
    func testPrepareForContainerSwap_KeepsSheetsThatHoldNoModels() async {
        let appState = AppState()
        appState.present(.addVehicle)

        appState.prepareForContainerSwap()

        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.addVehicle.id)
    }

    // MARK: - Sheet Payload Tests

    @MainActor
    func testMileageUpdateSheet_CarriesTheSiriReading() async {
        let appState = AppState()

        appState.present(.mileageUpdate(prefilled: 42_000))

        guard case .mileageUpdate(let prefilled) = appState.activeSheet else {
            return XCTFail("Expected the mileage update sheet")
        }
        XCTAssertEqual(prefilled, 42_000)
    }

    // MARK: - Recall State Storage Tests

    @MainActor
    func testSetRecalls_StoresResultsSortedNewestFirst() async {
        // Given
        let appState = AppState()
        let vehicleID = UUID()
        let older = RecallInfo(
            campaignNumber: "23V456", component: "FUEL", summary: "", consequence: "", remedy: "",
            reportDate: "06/20/2023", parkIt: false, parkOutside: false
        )
        let newest = RecallInfo(
            campaignNumber: "24V789", component: "STEERING", summary: "", consequence: "", remedy: "",
            reportDate: "03/10/2024", parkIt: false, parkOutside: false
        )

        // When
        appState.setRecalls([older, newest], for: vehicleID)

        // Then — stored newest-first, not a failed state
        XCTAssertEqual(appState.recall.recalls(for: vehicleID).map(\.campaignNumber), ["24V789", "23V456"])
        XCTAssertFalse(appState.recall.fetchFailed(for: vehicleID))
    }

    @MainActor
    func testSetRecalls_EmptyRecordsCheckedNoneFound() async {
        // Given
        let appState = AppState()
        let vehicleID = UUID()

        // When — mirrors a vehicle missing make/model/year
        appState.setRecalls([], for: vehicleID)

        // Then — a "fetched, empty" state, not a failure
        XCTAssertTrue(appState.recall.recalls(for: vehicleID).isEmpty)
        XCTAssertFalse(appState.recall.fetchFailed(for: vehicleID))
    }

    @MainActor
    func testSetRecallFetchFailed_MarksVehicleFailed() async {
        // Given
        let appState = AppState()
        let vehicleID = UUID()

        // When
        appState.setRecallFetchFailed(for: vehicleID)

        // Then
        XCTAssertTrue(appState.recall.fetchFailed(for: vehicleID))
        XCTAssertTrue(appState.recall.recalls(for: vehicleID).isEmpty)
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
