//
//  RecordedServiceUndoTests.swift
//  checkpointTests
//
//  Verifies that the undo snapshot produced after logging a service fully
//  reverses the save: removes what was created, restores what was completed,
//  and puts the odometer back exactly — prior value, prior timestamp, and no
//  leftover snapshot (F11).
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class RecordedServiceUndoTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self, MileageSnapshot.self,
            configurations: config
        )
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    private func makeVehicle(mileage: Int, updatedAt: Date?) -> Vehicle {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: mileage)
        vehicle.mileageUpdatedAt = updatedAt
        context.insert(vehicle)
        return vehicle
    }

    // MARK: - Mileage

    func testPerform_RestoresPriorMileageTimestampAndRemovesSnapshot() throws {
        let priorUpdatedAt = Date(timeIntervalSinceNow: -86400 * 10)
        let vehicle = makeVehicle(mileage: 30000, updatedAt: priorUpdatedAt)
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: .now, mileageAtService: 32000)
        context.insert(log)

        let revert = MileageCommit.commitIfNewestRevertibly(
            reading: 32000,
            observedAt: .now,
            source: .serviceCompletion,
            for: vehicle,
            in: context
        )
        XCTAssertNotNil(revert, "Precondition: the reading should have been adopted")
        XCTAssertEqual(revert?.insertedSnapshots.count, 1)

        let undo = RecordedServiceUndo(
            change: .created(service),
            log: log,
            attachments: [],
            vehicle: vehicle,
            mileageRevert: revert
        )
        undo.perform(in: context)
        try context.save()

        XCTAssertEqual(vehicle.currentMileage, 30000, "Undo should restore the prior odometer reading")
        XCTAssertEqual(vehicle.mileageUpdatedAt, priorUpdatedAt, "Undo should restore the prior timestamp, not stamp a new one")
        let snapshots = try context.fetch(FetchDescriptor<MileageSnapshot>())
        XCTAssertTrue(snapshots.isEmpty, "Undo must remove the snapshot the adoption wrote, not add another")
    }

    func testPerform_DoesNotClobberANewerReading() {
        let vehicle = makeVehicle(mileage: 30000, updatedAt: Date(timeIntervalSinceNow: -86400))
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: .now, mileageAtService: 32000)
        context.insert(log)

        let revert = MileageCommit.commitIfNewestRevertibly(
            reading: 32000,
            observedAt: .now,
            source: .serviceCompletion,
            for: vehicle,
            in: context
        )
        // The user updates the odometer before tapping UNDO.
        vehicle.recordMileage(32500, source: .manual, in: context)

        RecordedServiceUndo(
            change: .created(service),
            log: log,
            attachments: [],
            vehicle: vehicle,
            mileageRevert: revert
        ).perform(in: context)

        XCTAssertEqual(vehicle.currentMileage, 32500)
    }

    func testPerform_LeavesVehicleMileageAloneWhenNotAdopted() {
        // Backfill: the saved log was older, so nothing was adopted.
        let vehicle = makeVehicle(mileage: 32000, updatedAt: .now)
        let oldDate = Date(timeIntervalSinceNow: -86400 * 400)
        let service = Service(name: "Old Oil Change", lastPerformed: oldDate, lastMileage: 15000)
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: oldDate, mileageAtService: 15000)
        context.insert(log)

        let revert = MileageCommit.commitIfNewestRevertibly(
            reading: 15000,
            observedAt: oldDate,
            source: .serviceCompletion,
            for: vehicle,
            in: context
        )
        XCTAssertNil(revert)

        RecordedServiceUndo(
            change: .created(service),
            log: log,
            attachments: [],
            vehicle: vehicle,
            mileageRevert: revert
        ).perform(in: context)

        XCTAssertEqual(vehicle.currentMileage, 32000)
    }

    // MARK: - Records

    func testPerform_DeletesCreatedServiceAndLog() throws {
        let vehicle = makeVehicle(mileage: 30000, updatedAt: nil)
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 30000)
        context.insert(log)
        try context.save()

        RecordedServiceUndo(
            change: .created(service),
            log: log,
            attachments: [],
            vehicle: vehicle,
            mileageRevert: nil
        ).perform(in: context)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<ServiceLog>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Service>()).isEmpty)
    }

    func testPerform_DeletesAttachments() throws {
        let vehicle = makeVehicle(mileage: 30000, updatedAt: nil)
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 30000)
        context.insert(log)
        let attachment = ServiceAttachment(
            serviceLog: log,
            data: Data([0x00]),
            thumbnailData: nil,
            fileName: "receipt.jpg",
            mimeType: "image/jpeg",
            extractedText: nil
        )
        context.insert(attachment)
        try context.save()

        RecordedServiceUndo(
            change: .created(service),
            log: log,
            attachments: [attachment],
            vehicle: vehicle,
            mileageRevert: nil
        ).perform(in: context)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<ServiceAttachment>()).isEmpty)
    }

    func testPerform_CompletedService_RestoresScheduleAndDeletesSuccessor() throws {
        let vehicle = makeVehicle(mileage: 30000, updatedAt: nil)
        let due = Date(timeIntervalSinceNow: -86400 * 5)
        let service = Service(
            name: "Oil Change",
            dueDate: due,
            dueMileage: 29500,
            intervalMonths: 6,
            intervalMiles: 5000,
            isRecurring: true
        )
        service.vehicle = vehicle
        context.insert(service)
        let prior = ServiceScheduleState(capturing: service)

        let completion = ServiceCompletionService.recordCompletion(
            of: service,
            vehicle: vehicle,
            entry: .init(performedDate: .now, mileage: 30000, cost: nil, costCategory: nil, notes: nil, attachments: []),
            in: context
        )
        XCTAssertNotNil(completion.successor, "Precondition: a recurring completion spawns a successor")

        let undo = RecordedServiceUndo(
            change: .completed(service, prior: prior, successor: completion.successor),
            log: completion.log,
            attachments: completion.attachments,
            vehicle: vehicle,
            mileageRevert: nil
        )
        XCTAssertTrue(undo.leftFutureReminder)
        undo.perform(in: context)
        try context.save()

        XCTAssertEqual(ServiceScheduleState(capturing: service), prior)
        let services = try context.fetch(FetchDescriptor<Service>())
        XCTAssertEqual(services.map(\.id), [service.id], "The successor should be gone and the original kept")
        XCTAssertTrue(try context.fetch(FetchDescriptor<ServiceLog>()).isEmpty)
    }
}
