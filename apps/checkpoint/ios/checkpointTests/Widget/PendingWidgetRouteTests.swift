//
//  PendingWidgetRouteTests.swift
//  checkpointTests
//
//  The widget-tap → service-detail bridge: a stored route is taken once,
//  expires, and only well-formed IDs from OpenServiceIntent become one.
//

import XCTest
@testable import checkpoint

@MainActor
final class PendingWidgetRouteTests: XCTestCase {
    private let vehicleID = UUID()
    private let serviceID = UUID()

    override func tearDown() {
        _ = PendingWidgetRoute.take()
        super.tearDown()
    }

    func test_take_afterSave_returnsRouteOnce() {
        let route = PendingWidgetRoute(vehicleID: vehicleID, serviceID: serviceID, createdAt: Date())
        PendingWidgetRoute.save(route)

        XCTAssertEqual(PendingWidgetRoute.take(), route)
        XCTAssertNil(PendingWidgetRoute.take(), "A route navigates once")
    }

    func test_take_expiredRoute_returnsNilAndClears() {
        let old = Date().addingTimeInterval(-(PendingWidgetRoute.ttl + 1))
        PendingWidgetRoute.save(PendingWidgetRoute(vehicleID: vehicleID, serviceID: serviceID, createdAt: old))

        XCTAssertNil(PendingWidgetRoute.take())
        XCTAssertNil(WidgetAppGroup.defaults()?.data(forKey: WidgetAppGroup.pendingWidgetRouteKey))
    }

    func test_save_replacesEarlierRoute() {
        PendingWidgetRoute.save(PendingWidgetRoute(vehicleID: vehicleID, serviceID: UUID(), createdAt: Date()))
        let latest = PendingWidgetRoute(vehicleID: vehicleID, serviceID: serviceID, createdAt: Date())
        PendingWidgetRoute.save(latest)

        XCTAssertEqual(PendingWidgetRoute.take(), latest)
    }

    func test_openServiceIntent_malformedIDs_storeNothing() async throws {
        _ = try await OpenServiceIntent(serviceID: "not-a-uuid", vehicleID: vehicleID.uuidString).perform()
        XCTAssertNil(PendingWidgetRoute.take())
    }

    func test_openServiceIntent_validIDs_storeRoute() async throws {
        _ = try await OpenServiceIntent(serviceID: serviceID.uuidString, vehicleID: vehicleID.uuidString).perform()
        let route = PendingWidgetRoute.take()
        XCTAssertEqual(route?.serviceID, serviceID)
        XCTAssertEqual(route?.vehicleID, vehicleID)
    }
}
