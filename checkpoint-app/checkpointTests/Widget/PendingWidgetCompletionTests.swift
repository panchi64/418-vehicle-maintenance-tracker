//
//  PendingWidgetCompletionTests.swift
//  checkpointTests
//
//  Tests for PendingWidgetCompletion encoding/decoding and
//  WidgetDataService.processPendingWidgetCompletions
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class PendingWidgetCompletionTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self,
            MileageSnapshot.self, ServicePreset.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Encoding/Decoding

    func testEncodeDecode_roundTrip() throws {
        let completion = PendingWidgetCompletion(
            serviceID: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
            vehicleID: "11111111-2222-3333-4444-555555555555",
            performedDate: Date(timeIntervalSince1970: 1700000000),
            mileageAtService: 50000
        )

        let data = try JSONEncoder().encode(completion)
        let decoded = try JSONDecoder().decode(PendingWidgetCompletion.self, from: data)

        XCTAssertEqual(decoded.serviceID, completion.serviceID)
        XCTAssertEqual(decoded.vehicleID, completion.vehicleID)
        XCTAssertEqual(decoded.mileageAtService, completion.mileageAtService)
        XCTAssertEqual(decoded.performedDate.timeIntervalSince1970, completion.performedDate.timeIntervalSince1970, accuracy: 1)
    }

    func testEncodeDecode_multipleCompletions() throws {
        let completions = [
            PendingWidgetCompletion(
                serviceID: "AAA",
                vehicleID: "111",
                performedDate: Date(),
                mileageAtService: 50000
            ),
            PendingWidgetCompletion(
                serviceID: "BBB",
                vehicleID: "111",
                performedDate: Date(),
                mileageAtService: 50000
            )
        ]

        let data = try JSONEncoder().encode(completions)
        let decoded = try JSONDecoder().decode([PendingWidgetCompletion].self, from: data)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].serviceID, "AAA")
        XCTAssertEqual(decoded[1].serviceID, "BBB")
    }

    // MARK: - Processing Creates Correct ServiceLog

    func testProcessPendingWidgetCompletions_createsServiceLog() throws {
        // Create test vehicle and service
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 50000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            dueMileage: 49500,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        service.vehicle = vehicle
        modelContext.insert(service)
        try modelContext.save()

        // Simulate a pending widget completion via direct UserDefaults write
        let completion = PendingWidgetCompletion(
            serviceID: service.id.uuidString,
            vehicleID: vehicle.id.uuidString,
            performedDate: Date(),
            mileageAtService: 50000
        )

        // Write to UserDefaults (same key as PendingWidgetCompletion.save)
        let userDefaults = UserDefaults(suiteName: PendingWidgetCompletion.appGroupID)
        if let data = try? JSONEncoder().encode([completion]) {
            userDefaults?.set(data, forKey: PendingWidgetCompletion.userDefaultsKey)
        }

        // Process
        WidgetDataService.shared.processPendingWidgetCompletions(context: modelContext)

        // Verify ServiceLog was created
        let logs = try modelContext.fetch(FetchDescriptor<ServiceLog>())
        XCTAssertEqual(logs.count, 1, "Should create exactly one ServiceLog")

        let log = logs.first!
        XCTAssertEqual(log.mileageAtService, 50000)
        XCTAssertEqual(log.notes, "Completed via widget")
        XCTAssertEqual(log.service?.id, service.id)
        XCTAssertEqual(log.vehicle?.id, vehicle.id)

        // Verify service due dates were recalculated
        XCTAssertNotNil(service.lastPerformed)
        XCTAssertEqual(service.lastMileage, 50000)
        XCTAssertEqual(service.dueMileage, 55000, "Should add intervalMiles to mileageAtService")

        // Verify pending completions were cleared
        let remaining = PendingWidgetCompletion.loadAll()
        XCTAssertTrue(remaining.isEmpty, "Pending completions should be cleared after processing")

        // Cleanup
        userDefaults?.removeObject(forKey: PendingWidgetCompletion.userDefaultsKey)
    }

    func testProcessPendingWidgetCompletions_updatesMileageIfHigher() throws {
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 48000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Tire Rotation",
            dueMileage: 50000,
            intervalMiles: 5000
        )
        service.vehicle = vehicle
        modelContext.insert(service)
        try modelContext.save()

        let completion = PendingWidgetCompletion(
            serviceID: service.id.uuidString,
            vehicleID: vehicle.id.uuidString,
            performedDate: Date(),
            mileageAtService: 50000
        )

        let userDefaults = UserDefaults(suiteName: PendingWidgetCompletion.appGroupID)
        if let data = try? JSONEncoder().encode([completion]) {
            userDefaults?.set(data, forKey: PendingWidgetCompletion.userDefaultsKey)
        }

        WidgetDataService.shared.processPendingWidgetCompletions(context: modelContext)

        XCTAssertEqual(vehicle.currentMileage, 50000, "Should update vehicle mileage when widget mileage is higher")

        // Cleanup
        userDefaults?.removeObject(forKey: PendingWidgetCompletion.userDefaultsKey)
    }

    func testProcessPendingWidgetCompletions_doesNotDowngradeMileage() throws {
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 55000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Oil Change",
            dueMileage: 50000,
            intervalMiles: 5000
        )
        service.vehicle = vehicle
        modelContext.insert(service)
        try modelContext.save()

        let completion = PendingWidgetCompletion(
            serviceID: service.id.uuidString,
            vehicleID: vehicle.id.uuidString,
            performedDate: Date(),
            mileageAtService: 50000
        )

        let userDefaults = UserDefaults(suiteName: PendingWidgetCompletion.appGroupID)
        if let data = try? JSONEncoder().encode([completion]) {
            userDefaults?.set(data, forKey: PendingWidgetCompletion.userDefaultsKey)
        }

        WidgetDataService.shared.processPendingWidgetCompletions(context: modelContext)

        XCTAssertEqual(vehicle.currentMileage, 55000, "Should NOT downgrade vehicle mileage")

        // Cleanup
        userDefaults?.removeObject(forKey: PendingWidgetCompletion.userDefaultsKey)
    }

    func testProcessPendingWidgetCompletions_noOp_whenEmpty() {
        // No pending completions - should not crash
        WidgetDataService.shared.processPendingWidgetCompletions(context: modelContext)
        // Success if no crash
    }
}
