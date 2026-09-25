//
//  DuplicateServiceLogTests.swift
//  checkpointTests
//
//  Duplicating a history entry onto another vehicle. The form for the target
//  is the ordinary log form, so the save must behave exactly as logging there
//  would: complete the target's matching service, or create one — and the
//  odometer must be the target's reading, never the source's.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class DuplicateServiceLogTests: XCTestCase {
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

    // MARK: - Helpers

    private func makeVehicle(_ name: String, mileage: Int) -> Vehicle {
        let vehicle = Vehicle(name: name, make: "Honda", model: "Civic", year: 2020, currentMileage: mileage)
        vehicle.mileageUpdatedAt = Date(timeIntervalSinceNow: -86400 * 3)
        context.insert(vehicle)
        return vehicle
    }

    /// A past "Oil Change" on `vehicle`, with cost and notes to carry over.
    private func makeSourceLog(on vehicle: Vehicle) -> ServiceLog {
        let service = Service(
            name: "Oil Change",
            lastPerformed: Date(timeIntervalSinceNow: -86400 * 10),
            lastMileage: vehicle.currentMileage,
            intervalMonths: 6,
            intervalMiles: 5000,
            isRecurring: true
        )
        service.vehicle = vehicle
        context.insert(service)
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Date(timeIntervalSinceNow: -86400 * 10),
            mileageAtService: vehicle.currentMileage,
            cost: Decimal(45),
            costCategory: .maintenance,
            notes: "5W-30"
        )
        context.insert(log)
        return log
    }

    /// What the duplicate form does on open: a log-door model on `target`,
    /// prefilled from `log`, baselined.
    private func makeDuplicateModel(of log: ServiceLog, on target: Vehicle) -> ServiceLogFormModel {
        let model = ServiceLogFormModel(vehicle: target)
        model.applyTemplate(from: log)
        model.rebaseline()
        return model
    }

    /// The form's `logTarget`: the target vehicle's matching tracked service.
    private func match(for model: ServiceLogFormModel) throws -> Service? {
        let services = try context.fetch(FetchDescriptor<Service>())
        let logs = try context.fetch(FetchDescriptor<ServiceLog>())
        return services.activeMatch(
            named: model.serviceName,
            for: model.vehicle,
            performedDate: model.performedDate,
            logs: logs.filter { $0.vehicle?.id == model.vehicle.id }
        )
    }

    // MARK: - Saving to another vehicle

    func testDuplicateToOtherVehicle_WithMatchingService_CompletesIt() throws {
        let source = makeVehicle("Civic", mileage: 40000)
        let target = makeVehicle("Truck", mileage: 82000)
        let log = makeSourceLog(on: source)
        let tracked = Service(name: "Oil Change", dueMileage: 81500, intervalMonths: 3, intervalMiles: 3000, isRecurring: true)
        tracked.vehicle = target
        context.insert(tracked)

        let model = makeDuplicateModel(of: log, on: target)
        let completing = try match(for: model)
        XCTAssertEqual(completing?.id, tracked.id, "The target's own Oil Change should be the one completed")

        let undo = LoggedServiceWriter.save(model, completing: completing, in: context)

        XCTAssertEqual(undo.log.service?.id, tracked.id)
        XCTAssertEqual(undo.log.vehicle?.id, target.id)
        XCTAssertEqual(undo.log.mileageAtService, 82000, "Logged at the target's reading")
        XCTAssertEqual(undo.log.cost, Decimal(45), "Cost carries over from the source entry")
        XCTAssertEqual(undo.log.notes, "5W-30")
        let sourceServices = try context.fetch(FetchDescriptor<Service>()).filter { $0.vehicle?.id == source.id }
        XCTAssertEqual(sourceServices.count, 1, "Nothing new is written to the source vehicle")
        XCTAssertEqual(source.serviceLogs?.count ?? 0, 1)
    }

    func testDuplicateToOtherVehicle_NoMatch_CreatesService() throws {
        let source = makeVehicle("Civic", mileage: 40000)
        let target = makeVehicle("Truck", mileage: 82000)
        let log = makeSourceLog(on: source)

        let model = makeDuplicateModel(of: log, on: target)
        let completing = try match(for: model)
        XCTAssertNil(completing, "The source vehicle's service must never match on the target")

        let undo = LoggedServiceWriter.save(model, completing: completing, in: context)

        guard case .created(let service) = undo.change else {
            return XCTFail("Expected a new service on the target vehicle")
        }
        XCTAssertEqual(service.vehicle?.id, target.id)
        XCTAssertEqual(service.name, "Oil Change")
        XCTAssertEqual(service.intervalMonths, 6, "The source's cadence carries over")
        XCTAssertEqual(service.lastMileage, 82000)
        XCTAssertEqual(undo.log.vehicle?.id, target.id)
    }

    // MARK: - Odometer

    func testDuplicate_OdometerPrefill_ComesFromTargetVehicle() {
        let source = makeVehicle("Civic", mileage: 40000)
        let target = makeVehicle("Truck", mileage: 82000)
        let log = makeSourceLog(on: source)

        let model = makeDuplicateModel(of: log, on: target)

        XCTAssertEqual(model.mileageAtService, 82000)
    }

    func testCarryover_UntouchedOdometer_TakesTargetReading() {
        let source = makeVehicle("Civic", mileage: 40000)
        let target = makeVehicle("Truck", mileage: 82000)
        let log = makeSourceLog(on: source)
        let onSource = makeDuplicateModel(of: log, on: source)
        onSource.cost = "52"

        let carried = onSource.carryover(to: target)
        let onTarget = makeDuplicateModel(of: log, on: target)
        onTarget.apply(carried)

        XCTAssertEqual(onTarget.mileageAtService, 82000, "An untouched reading was the source's, not the user's")
        XCTAssertEqual(onTarget.cost, "52", "The user's edits carry over")
        XCTAssertTrue(onTarget.isDirty, "Carried-over edits keep the form dirty")
    }

    func testCarryover_EditedOdometer_IsKept() {
        let source = makeVehicle("Civic", mileage: 40000)
        let target = makeVehicle("Truck", mileage: 82000)
        let log = makeSourceLog(on: source)
        let onSource = makeDuplicateModel(of: log, on: source)
        onSource.mileageAtService = 83100

        XCTAssertEqual(onSource.carryover(to: target).mileageText, "83100")
    }
}
