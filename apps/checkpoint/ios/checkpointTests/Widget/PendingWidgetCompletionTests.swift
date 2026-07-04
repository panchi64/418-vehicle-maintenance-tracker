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
        PendingWidgetCompletion.clearAll()
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    private func makeCompletion(serviceID: String) -> PendingWidgetCompletion {
        PendingWidgetCompletion(
            serviceID: serviceID,
            vehicleID: "11111111-2222-3333-4444-555555555555",
            performedDate: Date(),
            mileageAtService: 50000
        )
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
            intervalMiles: 5000,
            isRecurring: true
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
        let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget)
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

        // Completed (original) service is closed.
        XCTAssertNotNil(service.lastPerformed)
        XCTAssertEqual(service.lastMileage, 50000)
        XCTAssertNil(service.dueMileage, "Closed occurrence has no forward-looking mileage")
        XCTAssertNil(service.dueDate, "Closed occurrence has no forward-looking date")

        // Chain-spawn produced the next occurrence with derived dates.
        let allServices = try modelContext.fetch(FetchDescriptor<Service>())
        let successor = allServices.first(where: { $0.id != service.id && $0.name == "Oil Change" })
        XCTAssertNotNil(successor, "Recurring widget completion should spawn a successor Service")
        XCTAssertEqual(successor?.dueMileage, 55000, "Next-occurrence dueMileage = completion mileage + interval")
        XCTAssertTrue(successor?.isRecurring == true)

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

        let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget)
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

        let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget)
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

    /// A completion whose vehicle/service don't exist can never succeed. Processing
    /// must drop it (it's counted as handled) so it doesn't retry every foreground.
    func testProcessPendingWidgetCompletions_removesUnmatchableCompletion() throws {
        let completion = PendingWidgetCompletion(
            serviceID: UUID().uuidString,
            vehicleID: UUID().uuidString,
            performedDate: Date(),
            mileageAtService: 50000
        )
        let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget)
        if let data = try? JSONEncoder().encode([completion]) {
            userDefaults?.set(data, forKey: PendingWidgetCompletion.userDefaultsKey)
        }

        WidgetDataService.shared.processPendingWidgetCompletions(context: modelContext)

        XCTAssertTrue(PendingWidgetCompletion.loadAll().isEmpty,
                      "Unmatchable completion should be removed, not retried forever")
        let logs = try modelContext.fetch(FetchDescriptor<ServiceLog>())
        XCTAssertTrue(logs.isEmpty, "No ServiceLog should be created for an unmatchable completion")
    }

    // MARK: - remove(serviceIDs:)

    func testRemove_dropsOnlySpecifiedIDs_keepsOthers() {
        PendingWidgetCompletion.save(makeCompletion(serviceID: "svc-A"))
        PendingWidgetCompletion.save(makeCompletion(serviceID: "svc-B"))
        PendingWidgetCompletion.save(makeCompletion(serviceID: "svc-C"))

        PendingWidgetCompletion.remove(serviceIDs: ["svc-A", "svc-C"])

        XCTAssertEqual(PendingWidgetCompletion.loadAll().map { $0.serviceID }, ["svc-B"],
                       "Only the named serviceIDs should be removed")
    }

    /// Models the widget enqueuing a completion mid-drain: the app's processed
    /// work-set is {A}, but by removal time the queue also holds a freshly
    /// enqueued D. remove(serviceIDs:) re-reads the queue and must preserve D.
    func testRemove_preservesEntryEnqueuedAfterWorkSetCaptured() {
        PendingWidgetCompletion.save(makeCompletion(serviceID: "svc-A"))
        PendingWidgetCompletion.save(makeCompletion(serviceID: "svc-D"))

        PendingWidgetCompletion.remove(serviceIDs: ["svc-A"])

        XCTAssertEqual(PendingWidgetCompletion.loadAll().map { $0.serviceID }, ["svc-D"],
                       "Completions outside the processed set must survive")
    }

    func testRemove_clearsKey_whenNothingRemains() {
        PendingWidgetCompletion.save(makeCompletion(serviceID: "svc-A"))
        PendingWidgetCompletion.save(makeCompletion(serviceID: "svc-B"))

        PendingWidgetCompletion.remove(serviceIDs: ["svc-A", "svc-B"])

        XCTAssertTrue(PendingWidgetCompletion.loadAll().isEmpty)
        let userDefaults = UserDefaults(suiteName: AppGroupConstants.iPhoneWidget)
        XCTAssertNil(userDefaults?.data(forKey: PendingWidgetCompletion.userDefaultsKey),
                     "Emptying the queue should remove the key, not leave an empty array")
    }

    func testRemove_emptySet_isNoOp() {
        PendingWidgetCompletion.save(makeCompletion(serviceID: "svc-A"))

        PendingWidgetCompletion.remove(serviceIDs: [])

        XCTAssertEqual(PendingWidgetCompletion.loadAll().map { $0.serviceID }, ["svc-A"])
    }
}
