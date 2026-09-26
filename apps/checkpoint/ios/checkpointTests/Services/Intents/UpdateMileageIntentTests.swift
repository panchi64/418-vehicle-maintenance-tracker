//
//  UpdateMileageIntentTests.swift
//  checkpointTests
//
//  UpdateMileageIntent opens the app on the mileage sheet with the spoken
//  reading filled in, through the shared pending-route store.
//

import XCTest
@testable import checkpoint

@MainActor
final class UpdateMileageIntentTests: XCTestCase {

    override func tearDown() {
        PendingRouteStore.shared.route = nil
        super.tearDown()
    }

    func test_perform_queuesPrefilledMileageRoute() async throws {
        let vehicle = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020, currentMileage: 50_000)
        let intent = UpdateMileageIntent()
        intent.vehicle = VehicleEntity(model: vehicle)
        intent.mileage = 52_000

        _ = try await intent.perform()

        XCTAssertEqual(
            PendingRouteStore.shared.route,
            .updateMileage(vehicleID: vehicle.id, prefilled: 52_000)
        )
    }

    // MARK: - Intent Creation Tests

    func test_updateMileageIntent_hasCorrectTitle() {
        let title = UpdateMileageIntent.title
        XCTAssertNotNil(title)
    }

    func test_updateMileageIntent_opensAppWhenRun() {
        XCTAssertTrue(UpdateMileageIntent.openAppWhenRun)
    }
}
