//
//  RecordedServiceUndoTests.swift
//  checkpointTests
//
//  Verifies that the undo snapshot produced after recording a service can
//  fully reverse the save: removes the service, log, and attachments, and
//  restores the vehicle's odometer to its prior value.
//

import XCTest
import SwiftData
@testable import checkpoint

final class RecordedServiceUndoTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self,
            configurations: config
        )
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    @MainActor
    func testPerform_RestoresVehicleMileageWhenItHadBeenBumped() {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        context.insert(vehicle)
        let service = Service(name: "Oil Change", lastPerformed: Date(), lastMileage: 32000)
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 32000)
        context.insert(log)
        // Simulate the save-time bump.
        vehicle.currentMileage = 32000

        let undo = RecordedServiceUndo(
            service: service,
            log: log,
            attachments: [],
            vehicle: vehicle,
            priorVehicleMileage: 30000
        )

        undo.perform(in: context)

        XCTAssertEqual(vehicle.currentMileage, 30000, "Undo should restore the prior odometer reading")
    }

    @MainActor
    func testPerform_LeavesVehicleMileageAloneWhenUnchanged() {
        // Backfill scenario: the saved log was older, vehicle.currentMileage was never bumped.
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 32000)
        context.insert(vehicle)
        let service = Service(name: "Old Oil Change", lastPerformed: Date(timeIntervalSinceNow: -86400 * 400), lastMileage: 15000)
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(timeIntervalSinceNow: -86400 * 400), mileageAtService: 15000)
        context.insert(log)

        let undo = RecordedServiceUndo(
            service: service,
            log: log,
            attachments: [],
            vehicle: vehicle,
            priorVehicleMileage: 32000
        )

        undo.perform(in: context)

        XCTAssertEqual(vehicle.currentMileage, 32000)
    }

    @MainActor
    func testPerform_DeletesServiceAndLog() throws {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        context.insert(vehicle)
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 30000)
        context.insert(log)
        try context.save()

        let undo = RecordedServiceUndo(
            service: service,
            log: log,
            attachments: [],
            vehicle: vehicle,
            priorVehicleMileage: 30000
        )

        undo.perform(in: context)
        try context.save()

        let remainingLogs = try context.fetch(FetchDescriptor<ServiceLog>())
        let remainingServices = try context.fetch(FetchDescriptor<Service>())
        XCTAssertTrue(remainingLogs.isEmpty)
        XCTAssertTrue(remainingServices.isEmpty)
    }

    @MainActor
    func testPerform_DeletesAttachments() throws {
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        context.insert(vehicle)
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

        let undo = RecordedServiceUndo(
            service: service,
            log: log,
            attachments: [attachment],
            vehicle: vehicle,
            priorVehicleMileage: 30000
        )

        undo.perform(in: context)
        try context.save()

        let remainingAttachments = try context.fetch(FetchDescriptor<ServiceAttachment>())
        XCTAssertTrue(remainingAttachments.isEmpty)
    }
}
