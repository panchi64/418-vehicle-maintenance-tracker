//
//  NavigationColumnTests.swift
//  checkpointTests
//
//  Regular-width navigation: which routes open a tab's detail column, push vs.
//  replace from each column, and that `AppState.paths` — the one navigation
//  state — carries across a size-class flip (folding the Duo).
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

@MainActor
final class NavigationColumnTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        modelContainer = .inMemoryForTesting()
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    private func makeRoutes() -> (service: AppRoute, log: AppRoute, visit: AppRoute, document: AppRoute, documents: AppRoute, notes: AppRoute) {
        let vehicle = Vehicle(name: "Daily", make: "Toyota", model: "Camry", year: 2022)
        let service = Service(name: "Oil Change")
        let log = ServiceLog(performedDate: .now, mileageAtService: 32000, cost: 45)
        let visit = ServiceVisit(vehicle: vehicle, totalCost: 120)
        let document = ServiceAttachment(fileName: "receipt.jpg", mimeType: "image/jpeg")
        modelContext.insert(vehicle)
        modelContext.insert(service)
        modelContext.insert(log)
        modelContext.insert(visit)
        modelContext.insert(document)
        return (.service(service), .serviceLog(log), .visit(visit), .document(document), .documents(vehicle), .notes(vehicle))
    }

    // MARK: - isColumnRoot

    func test_isColumnRoot_services_opensItsListsDestinations() {
        let r = makeRoutes()
        XCTAssertTrue(r.service.isColumnRoot(for: .services))
        XCTAssertTrue(r.log.isColumnRoot(for: .services))
        XCTAssertTrue(r.documents.isColumnRoot(for: .services))
        XCTAssertFalse(r.visit.isColumnRoot(for: .services))
        XCTAssertFalse(r.document.isColumnRoot(for: .services))
        XCTAssertFalse(r.notes.isColumnRoot(for: .services))
    }

    func test_isColumnRoot_costs_opensLogsAndVisits() {
        let r = makeRoutes()
        XCTAssertTrue(r.log.isColumnRoot(for: .costs))
        XCTAssertTrue(r.visit.isColumnRoot(for: .costs))
        XCTAssertFalse(r.service.isColumnRoot(for: .costs))
        XCTAssertFalse(r.documents.isColumnRoot(for: .costs))
    }

    func test_isColumnRoot_home_hasNoColumns() {
        let r = makeRoutes()
        for route in [r.service, r.log, r.visit, r.document, r.documents, r.notes] {
            XCTAssertFalse(route.isColumnRoot(for: .home))
        }
    }

    // MARK: - Open: replace vs. append

    func test_path_fromListColumn_replacesTheDetail() {
        let r = makeRoutes()
        let path = AppState.path([r.service, r.visit], opening: r.log, from: .list, on: .services)
        XCTAssertEqual(path, [r.log])
    }

    func test_path_fromListColumn_nonColumnRoot_appends() {
        let r = makeRoutes()
        let path = AppState.path([r.service], opening: r.document, from: .list, on: .services)
        XCTAssertEqual(path, [r.service, r.document])
    }

    func test_path_fromDetailColumn_appends() {
        let r = makeRoutes()
        let path = AppState.path([r.service], opening: r.log, from: .detail, on: .services)
        XCTAssertEqual(path, [r.service, r.log])
    }

    func test_path_fromStack_appends() {
        let r = makeRoutes()
        let path = AppState.path([r.service], opening: r.log, from: .stack, on: .services)
        XCTAssertEqual(path, [r.service, r.log])
    }

    func test_open_writesTheTabsPathOnly() {
        let r = makeRoutes()
        let appState = AppState()
        appState.paths[.services] = [r.service, r.visit]

        appState.open(r.log, from: .list, on: .costs)

        XCTAssertEqual(appState.paths[.costs], [r.log])
        XCTAssertEqual(appState.paths[.services], [r.service, r.visit])
    }

    // MARK: - Size-class flip

    func test_usesColumns_onlyRegularListTabs() {
        XCTAssertTrue(TabColumnsStack<EmptyView>.usesColumns(for: .services, in: .regular))
        XCTAssertTrue(TabColumnsStack<EmptyView>.usesColumns(for: .costs, in: .regular))
        XCTAssertFalse(TabColumnsStack<EmptyView>.usesColumns(for: .home, in: .regular))
        XCTAssertFalse(TabColumnsStack<EmptyView>.usesColumns(for: .services, in: .compact))
        XCTAssertFalse(TabColumnsStack<EmptyView>.usesColumns(for: .costs, in: nil))
    }

    /// Unfolded: a row opens beside the list, and a link inside it pushes.
    /// Folded: the same path is the compact stack, so back walks it; opening
    /// another row there pushes rather than replacing.
    func test_paths_surviveAModeFlip() {
        let r = makeRoutes()
        let appState = AppState()

        appState.open(r.service, from: .list, on: .services)
        appState.open(r.visit, from: .detail, on: .services)
        XCTAssertEqual(appState.paths[.services], [r.service, r.visit])

        // Fold: nothing about the state changes, only which view reads it.
        appState.open(r.document, from: .stack, on: .services)
        XCTAssertEqual(appState.paths[.services], [r.service, r.visit, r.document])

        // Unfold and pick another row: the detail is replaced.
        appState.open(r.log, from: .list, on: .services)
        XCTAssertEqual(appState.paths[.services], [r.log])
    }

    func test_selectVehicle_clearsTheDetailColumn() {
        let r = makeRoutes()
        let appState = AppState()
        appState.open(r.service, from: .list, on: .services)
        appState.open(r.visit, from: .list, on: .costs)

        appState.selectVehicle(Vehicle(name: "Other", make: "Honda", model: "Civic", year: 2020))

        XCTAssertNil(appState.paths[.services])
        XCTAssertNil(appState.paths[.costs])
    }

    // MARK: - Deleted detail

    func test_prefixBeforeGone_dropsADeletedDetailAndWhatFollows() throws {
        let r = makeRoutes()
        guard case .serviceLog(let log) = r.log else { return XCTFail() }

        modelContext.delete(log)
        try modelContext.save()

        XCTAssertEqual([r.service, r.log, r.visit].prefixBeforeGone(), [r.service])
        XCTAssertEqual([r.service, r.visit].prefixBeforeGone(), [r.service, r.visit])
    }
}
