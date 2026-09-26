//
//  PendingWidgetRouteTests.swift
//  checkpointTests
//
//  The widget/Control → app bridge: a stored route is taken once, expires,
//  and only well-formed IDs from OpenServiceIntent become one. A Control's
//  screen opens on the vehicle the app is showing, on the screen it names.
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

    private func serviceRoute(_ serviceID: UUID, createdAt: Date = Date()) -> PendingWidgetRoute {
        PendingWidgetRoute(destination: .service(vehicleID: vehicleID, serviceID: serviceID), createdAt: createdAt)
    }

    func test_take_afterSave_returnsRouteOnce() {
        let route = serviceRoute(serviceID)
        PendingWidgetRoute.save(route)

        XCTAssertEqual(PendingWidgetRoute.take(), route)
        XCTAssertNil(PendingWidgetRoute.take(), "A route navigates once")
    }

    func test_take_expiredRoute_returnsNilAndClears() {
        let old = Date().addingTimeInterval(-(PendingWidgetRoute.ttl + 1))
        PendingWidgetRoute.save(serviceRoute(serviceID, createdAt: old))

        XCTAssertNil(PendingWidgetRoute.take())
        XCTAssertNil(WidgetAppGroup.defaults()?.data(forKey: WidgetAppGroup.pendingWidgetRouteKey))
    }

    func test_save_replacesEarlierRoute() {
        PendingWidgetRoute.save(serviceRoute(UUID()))
        let latest = serviceRoute(serviceID)
        PendingWidgetRoute.save(latest)

        XCTAssertEqual(PendingWidgetRoute.take(), latest)
    }

    // `queue` rather than the intents' `perform()`: running an AppIntent
    // outside the system's intent runtime hung the test host intermittently,
    // and perform's notification post would drive the host app's navigation.

    func test_queue_malformedIDs_storeNothing() {
        XCTAssertFalse(PendingWidgetRoute.queue(serviceID: "not-a-uuid", vehicleID: vehicleID.uuidString))
        XCTAssertNil(PendingWidgetRoute.take())
    }

    func test_queue_validIDs_storeRoute() {
        XCTAssertTrue(PendingWidgetRoute.queue(serviceID: serviceID.uuidString, vehicleID: vehicleID.uuidString))
        XCTAssertEqual(PendingWidgetRoute.take()?.destination, .service(vehicleID: vehicleID, serviceID: serviceID))
    }

    // MARK: - Controls

    func test_queueScreen_storesTheControlsScreen() {
        PendingWidgetRoute.queue(.scanReceipt)
        XCTAssertEqual(PendingWidgetRoute.take()?.destination, .screen(.scanReceipt))
    }

    func test_controlScreens_openOnTheVehicleShowing() {
        let expected: [CheckpointScreen: PendingRoute] = [
            .updateMileage: .updateMileage(vehicleID: vehicleID),
            .scanReceipt: .scanReceipt(vehicleID: vehicleID),
            .logService: .logService(vehicleID: vehicleID),
        ]
        for (screen, route) in expected {
            PendingWidgetRoute.queue(screen)
            let taken = PendingWidgetRoute.take()!
            XCTAssertEqual(PendingRoute(taken, currentVehicleID: vehicleID), route, "\(screen)")
        }
    }

    func test_controlScreen_withNoVehicle_goesNowhere() {
        let route = PendingWidgetRoute(destination: .screen(.logService), createdAt: Date())
        XCTAssertNil(PendingRoute(route, currentVehicleID: nil))
    }

    func test_widgetRow_keepsItsOwnVehicle() {
        let other = UUID()
        XCTAssertEqual(PendingRoute(serviceRoute(serviceID), currentVehicleID: other),
                       .service(vehicleID: vehicleID, serviceID: serviceID))
    }

    func test_controlIntent_targetsItsScreen() {
        XCTAssertEqual(OpenCheckpointScreenIntent(target: .updateMileage).target, .updateMileage)
    }
}
