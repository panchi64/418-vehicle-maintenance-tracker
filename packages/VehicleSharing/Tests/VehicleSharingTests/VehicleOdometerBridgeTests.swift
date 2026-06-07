import XCTest
@testable import VehicleSharing

final class VehicleOdometerBridgeTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test.vehiclesharing.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Publish / read round-trip

    func testPublishThenReadRoundTrips() {
        let vehicles = [
            SharedVehicleOdometer(
                id: "v1", displayName: "Daily Driver", currentMileage: 32500,
                estimatedMileage: 32620, isEstimated: true,
                distanceUnit: .miles, updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            SharedVehicleOdometer(
                id: "v2", displayName: "Weekend Car", currentMileage: 18200,
                distanceUnit: .kilometers
            )
        ]

        VehicleOdometerBridge.publish(vehicles, defaults: defaults)
        let read = VehicleOdometerBridge.readVehicles(defaults: defaults)

        XCTAssertEqual(read, vehicles)
    }

    func testReadWithNoDataReturnsEmpty() {
        XCTAssertTrue(VehicleOdometerBridge.readVehicles(defaults: defaults).isEmpty)
    }

    func testPublishReplacesPreviousList() {
        VehicleOdometerBridge.publish(
            [SharedVehicleOdometer(id: "v1", displayName: "A", currentMileage: 1)],
            defaults: defaults
        )
        VehicleOdometerBridge.publish(
            [SharedVehicleOdometer(id: "v2", displayName: "B", currentMileage: 2)],
            defaults: defaults
        )
        let read = VehicleOdometerBridge.readVehicles(defaults: defaults)
        XCTAssertEqual(read.map(\.id), ["v2"])
    }

    // MARK: - Pending queue

    func testQueueAppendsAndDrainClears() {
        let u1 = PendingOdometerUpdate(vehicleID: "v1", mileage: 33000, recordedAt: Date(timeIntervalSince1970: 1))
        let u2 = PendingOdometerUpdate(vehicleID: "v1", mileage: 33100, recordedAt: Date(timeIntervalSince1970: 2))

        VehicleOdometerBridge.queueUpdate(u1, defaults: defaults)
        VehicleOdometerBridge.queueUpdate(u2, defaults: defaults)

        XCTAssertEqual(VehicleOdometerBridge.loadPendingUpdates(defaults: defaults), [u1, u2])

        let drained = VehicleOdometerBridge.drainPendingUpdates(defaults: defaults)
        XCTAssertEqual(drained, [u1, u2])
        XCTAssertTrue(VehicleOdometerBridge.loadPendingUpdates(defaults: defaults).isEmpty)
    }

    func testDrainEmptyReturnsEmpty() {
        XCTAssertTrue(VehicleOdometerBridge.drainPendingUpdates(defaults: defaults).isEmpty)
    }

    // MARK: - Unit conversion

    func testDistanceUnitConversionRoundTrips() {
        XCTAssertEqual(SharedDistanceUnit.miles.fromMiles(100), 100)
        XCTAssertEqual(SharedDistanceUnit.miles.toMiles(100), 100)
        XCTAssertEqual(SharedDistanceUnit.kilometers.fromMiles(100), 161)
        XCTAssertEqual(SharedDistanceUnit.kilometers.toMiles(161), 100)
    }

    func testApplyingReadingClearsEstimateAndMovesForward() {
        let base = SharedVehicleOdometer(
            id: "v1", displayName: "A", currentMileage: 50000,
            estimatedMileage: 50200, isEstimated: true,
            distanceUnit: .miles, updatedAt: Date(timeIntervalSince1970: 1)
        )
        let when = Date(timeIntervalSince1970: 2)

        let updated = base.applyingReading(50500, at: when)
        XCTAssertEqual(updated.currentMileage, 50500)
        XCTAssertNil(updated.estimatedMileage)
        XCTAssertFalse(updated.isEstimated)
        XCTAssertEqual(updated.updatedAt, when)
        XCTAssertEqual(updated.distanceUnit, .miles)

        // Never moves backwards.
        let lower = base.applyingReading(49000, at: when)
        XCTAssertEqual(lower.currentMileage, 50000)
    }

    func testDisplayMileagePrefersEstimateWhenFlagged() {
        let estimated = SharedVehicleOdometer(
            id: "v1", displayName: "A", currentMileage: 100,
            estimatedMileage: 150, isEstimated: true
        )
        XCTAssertEqual(estimated.displayMileage, 150)

        let actual = SharedVehicleOdometer(
            id: "v2", displayName: "B", currentMileage: 100,
            estimatedMileage: 150, isEstimated: false
        )
        XCTAssertEqual(actual.displayMileage, 100)
    }
}
