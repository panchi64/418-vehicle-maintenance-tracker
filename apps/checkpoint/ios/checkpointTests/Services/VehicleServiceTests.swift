//
//  VehicleServiceTests.swift
//  checkpointTests
//
//  Covers the vehicle create/update path shared by the vehicle forms and App
//  Intents: empty-string normalization, the unknown-year rule, mileage edits
//  recorded as readings, and the free-tier vehicle limit.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class VehicleServiceTests: XCTestCase {

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

    // MARK: - Pro limit

    func test_requiresPro_belowLimit_isFalse() {
        XCTAssertFalse(VehicleService.requiresPro(toAddTo: 2, isPro: false))
    }

    func test_requiresPro_atLimit_isTrueForFreeUsers() {
        XCTAssertTrue(VehicleService.requiresPro(toAddTo: VehicleService.freeVehicleLimit, isPro: false))
    }

    func test_requiresPro_atLimit_isFalseForPro() {
        XCTAssertFalse(VehicleService.requiresPro(toAddTo: 10, isPro: true))
    }

    // MARK: - Create

    func test_create_insertsVehicleWithFields() throws {
        let fields = VehicleFields(
            name: "Daily",
            make: "Honda",
            model: "Civic",
            year: 2020,
            currentMileage: 45_000,
            vin: "1HGBH41JXMN109186",
            licensePlate: "ABC123",
            tireSize: "215/55R16",
            oilType: "0W-20"
        )

        let vehicle = VehicleService.create(fields, in: modelContext)

        let stored = try modelContext.fetch(FetchDescriptor<Vehicle>())
        XCTAssertEqual(stored.map(\.id), [vehicle.id])
        XCTAssertEqual(vehicle.name, "Daily")
        XCTAssertEqual(vehicle.identityLine, "2020 Honda Civic")
        XCTAssertEqual(vehicle.currentMileage, 45_000)
        XCTAssertEqual(vehicle.vin, "1HGBH41JXMN109186")
        XCTAssertEqual(vehicle.licensePlate, "ABC123")
        XCTAssertEqual(vehicle.tireSize, "215/55R16")
        XCTAssertEqual(vehicle.oilType, "0W-20")
    }

    func test_create_emptyStringsAndMissingYear_storeAsUnset() {
        let fields = VehicleFields(make: "Honda", model: "Civic", currentMileage: 100)

        let vehicle = VehicleService.create(fields, in: modelContext)

        XCTAssertEqual(vehicle.year, 0, "0 is the stored 'unknown year'")
        XCTAssertFalse(vehicle.hasModelYear)
        XCTAssertNil(vehicle.vin)
        XCTAssertNil(vehicle.licensePlate)
        XCTAssertNil(vehicle.tireSize)
        XCTAssertNil(vehicle.oilType)
        XCTAssertNil(vehicle.notes)
    }

    func test_create_copiesMarbete() {
        var fields = VehicleFields(make: "Honda", model: "Civic", currentMileage: 100)
        fields.marbeteExpirationMonth = 6
        fields.marbeteExpirationYear = 2030

        let vehicle = VehicleService.create(fields, in: modelContext)

        XCTAssertTrue(vehicle.hasMarbeteExpiration)
        XCTAssertEqual(vehicle.marbeteExpirationMonth, 6)
        XCTAssertEqual(vehicle.marbeteExpirationYear, 2030)
    }

    // MARK: - Update

    func test_update_roundTripsFieldsAndClearsEmptied() {
        let vehicle = Vehicle(name: "Old", make: "Toyota", model: "Camry", year: 2018,
                              currentMileage: 30_000, vin: "VIN", licensePlate: "PLATE")
        modelContext.insert(vehicle)

        var fields = VehicleFields(vehicle: vehicle)
        fields.name = "New"
        fields.licensePlate = ""
        fields.oilType = "5W-30"

        VehicleService.update(vehicle, with: fields, in: modelContext)

        XCTAssertEqual(vehicle.name, "New")
        XCTAssertNil(vehicle.licensePlate)
        XCTAssertEqual(vehicle.oilType, "5W-30")
        XCTAssertEqual(vehicle.vin, "VIN")
        XCTAssertEqual(VehicleFields(vehicle: vehicle), fields)
    }

    func test_update_changedMileage_recordsReading() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2018, currentMileage: 30_000)
        modelContext.insert(vehicle)

        var fields = VehicleFields(vehicle: vehicle)
        fields.currentMileage = 31_000
        VehicleService.update(vehicle, with: fields, in: modelContext)

        XCTAssertEqual(vehicle.currentMileage, 31_000)
        XCTAssertNotNil(vehicle.mileageUpdatedAt, "A changed odometer is a dated reading")
        XCTAssertEqual(vehicle.mileageSnapshots?.count, 1)
    }

    func test_update_unchangedMileage_recordsNoReading() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2018, currentMileage: 30_000)
        modelContext.insert(vehicle)

        var fields = VehicleFields(vehicle: vehicle)
        fields.name = "Renamed"
        VehicleService.update(vehicle, with: fields, in: modelContext)

        XCTAssertNil(vehicle.mileageUpdatedAt)
        XCTAssertEqual(vehicle.mileageSnapshots?.count ?? 0, 0)
    }

    func test_update_clearingMarbete_removesIt() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2018, currentMileage: 30_000,
                              marbeteExpirationMonth: 3, marbeteExpirationYear: 2030)
        modelContext.insert(vehicle)

        var fields = VehicleFields(vehicle: vehicle)
        fields.marbeteExpirationMonth = nil
        fields.marbeteExpirationYear = nil
        VehicleService.update(vehicle, with: fields, in: modelContext)

        XCTAssertFalse(vehicle.hasMarbeteExpiration)
    }
}
