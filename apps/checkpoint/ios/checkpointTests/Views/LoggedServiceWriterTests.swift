//
//  LoggedServiceWriterTests.swift
//  checkpointTests
//
//  The add form's log path. Guards three regressions:
//
//  - Logging a service already on the schedule created a duplicate beside the
//    one counting down, instead of completing it.
//  - A preset silently turned recurrence on, and the reminder it created was
//    never shown. The preview must now equal what gets saved (F4).
//  - An adopted odometer reading must write the snapshot and timestamp (F11).
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class LoggedServiceWriterTests: XCTestCase {
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

    private func makeVehicle(mileage: Int = 30000) -> Vehicle {
        let vehicle = Vehicle(name: "Daily", make: "Toyota", model: "Camry", year: 2022, currentMileage: mileage)
        vehicle.mileageUpdatedAt = Date(timeIntervalSinceNow: -86400 * 3)
        context.insert(vehicle)
        return vehicle
    }

    @discardableResult
    private func makeTrackedService(
        _ name: String = "Oil Change",
        on vehicle: Vehicle,
        dueMileage: Int? = 29600,
        intervalMonths: Int? = 3,
        intervalMiles: Int? = 3000,
        isRecurring: Bool = true
    ) -> Service {
        let service = Service(
            name: name,
            dueMileage: dueMileage,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            isRecurring: isRecurring
        )
        service.vehicle = vehicle
        context.insert(service)
        return service
    }

    private func makeLogModel(for vehicle: Vehicle, name: String = "Oil Change") -> AddServiceFormModel {
        let model = AddServiceFormModel(vehicle: vehicle, initialTiming: .today)
        model.customServiceName = name
        return model
    }

    /// `.today` resolves `performedDate` to `Date.now` on every read, so a
    /// preview and a save a few microseconds apart would differ for reasons
    /// unrelated to F4. A fixed explicit date isolates the calculation.
    private func makeFixedDateLogModel(for vehicle: Vehicle, name: String) -> AddServiceFormModel {
        let model = AddServiceFormModel(vehicle: vehicle, initialTiming: .earlier)
        model.customDate = Date(timeIntervalSinceNow: -86400)
        model.customServiceName = name
        return model
    }

    private func allServices() throws -> [Service] {
        try context.fetch(FetchDescriptor<Service>())
    }

    // MARK: - Matching

    func testActiveMatch_SameNameTrackedService_Matches() throws {
        let vehicle = makeVehicle()
        let tracked = makeTrackedService(on: vehicle)

        let match = try allServices().activeMatch(named: "oil change ", for: vehicle, performedDate: .now, logs: [])

        XCTAssertEqual(match?.id, tracked.id, "Name matching should ignore case and surrounding whitespace")
    }

    func testActiveMatch_ClosedServiceWithoutDueTracking_DoesNotMatch() throws {
        let vehicle = makeVehicle()
        makeTrackedService(on: vehicle, dueMileage: nil, intervalMonths: nil, intervalMiles: nil, isRecurring: false)

        XCTAssertNil(try allServices().activeMatch(named: "Oil Change", for: vehicle, performedDate: .now, logs: []))
    }

    func testActiveMatch_OtherVehicle_DoesNotMatch() throws {
        let vehicle = makeVehicle()
        let other = makeVehicle()
        makeTrackedService(on: other)

        XCTAssertNil(try allServices().activeMatch(named: "Oil Change", for: vehicle, performedDate: .now, logs: []))
    }

    func testActiveMatch_BackfillOlderThanNewestLog_DoesNotMatch() throws {
        let vehicle = makeVehicle()
        let tracked = makeTrackedService(on: vehicle)
        let recent = ServiceLog(
            service: tracked,
            vehicle: vehicle,
            performedDate: Date(timeIntervalSinceNow: -86400 * 30),
            mileageAtService: 27000
        )
        context.insert(recent)

        let match = try allServices().activeMatch(
            named: "Oil Change",
            for: vehicle,
            performedDate: Date(timeIntervalSinceNow: -86400 * 400),
            logs: [recent]
        )

        XCTAssertNil(match, "History older than the newest record must not complete the live occurrence")
    }

    // MARK: - Completing a match

    func testSave_WithMatch_CompletesExistingServiceInsteadOfDuplicating() throws {
        let vehicle = makeVehicle()
        let tracked = makeTrackedService(on: vehicle)
        let model = makeLogModel(for: vehicle)
        model.mileageAtService = 30000
        model.applyScheduleDefaults(preset: nil, match: tracked)

        let undo = LoggedServiceWriter.save(model, completing: tracked, in: context)

        XCTAssertEqual(undo.log.service?.id, tracked.id, "The log should attach to the tracked service")
        XCTAssertEqual(tracked.lastMileage, 30000)
        XCTAssertNotNil(tracked.lastPerformed)
        XCTAssertFalse(tracked.hasDueTracking, "The completed occurrence should close, as Mark Done closes it")

        let oilChanges = try allServices().filter { $0.name == "Oil Change" }
        XCTAssertEqual(oilChanges.count, 2, "Only the closed original and its successor — no duplicate")
        guard case .completed(_, _, let successor?) = undo.change else {
            return XCTFail("Expected a completion with a successor")
        }
        XCTAssertEqual(successor.intervalMonths, 3, "The match's own cadence should carry forward, not a preset's")
        XCTAssertEqual(successor.intervalMiles, 3000)
    }

    func testApplyScheduleDefaults_MatchCadenceWinsOverPreset() {
        let vehicle = makeVehicle()
        let tracked = makeTrackedService(on: vehicle)
        let model = makeLogModel(for: vehicle)
        let preset = PresetData(name: "Oil Change", category: "Engine", defaultIntervalMonths: 6, defaultIntervalMiles: 5000)

        model.applyScheduleDefaults(preset: preset, match: tracked)

        XCTAssertEqual(model.intervalMonths, 3)
        XCTAssertEqual(model.intervalMiles, 3000)
        XCTAssertTrue(model.isRecurring)
    }

    func testApplyScheduleDefaults_BackfillWithoutMatch_DoesNotRecur() {
        let vehicle = makeVehicle()
        let model = AddServiceFormModel(vehicle: vehicle, initialTiming: .earlier)
        let preset = PresetData(name: "Oil Change", category: "Engine", defaultIntervalMonths: 6, defaultIntervalMiles: 5000)

        model.applyScheduleDefaults(preset: preset, match: nil)

        XCTAssertFalse(model.isRecurring)
        XCTAssertNil(model.nextReminderAfterLog)
    }

    func testCompletesAdvisory_NamesServiceAndUrgency() {
        let vehicle = makeVehicle(mileage: 30000)
        let tracked = makeTrackedService(on: vehicle, dueMileage: 29600)

        let text = AddServiceView.completesAdvisory(for: tracked, vehicle: vehicle)

        XCTAssertTrue(text.contains("Oil Change"))
        XCTAssertEqual(
            text,
            L10n.formCompletesServiceWithStatus("Oil Change", tracked.urgencyText(currentMileage: 30000) ?? "")
        )
    }

    // MARK: - Recurring preview (F4)

    func testNextReminderPreview_EqualsSavedSchedule_CreatedService() throws {
        let vehicle = makeVehicle()
        let model = makeFixedDateLogModel(for: vehicle, name: "Tire Rotation")
        model.mileageAtService = 31000
        model.applyScheduleDefaults(
            preset: PresetData(name: "Tire Rotation", category: "Tires", defaultIntervalMonths: 6, defaultIntervalMiles: 5000),
            match: nil
        )
        // `.earlier` is backfill, so defaults leave recurrence off; the user
        // switching it on is the case under test.
        model.isRecurring = true
        let preview = try XCTUnwrap(model.nextReminderAfterLog, "A preset cadence on the log path must be previewed")

        let undo = LoggedServiceWriter.save(model, completing: nil, in: context)

        guard case .created(let service) = undo.change else { return XCTFail("Expected a created service") }
        XCTAssertEqual(service.dueDate, preview.dueDate)
        XCTAssertEqual(service.dueMileage, preview.dueMileage)
        XCTAssertEqual(preview.dueMileage, 36000)
    }

    func testNextReminderPreview_EqualsSavedSchedule_CompletedMatch() throws {
        let vehicle = makeVehicle()
        let tracked = makeTrackedService(on: vehicle)
        let model = makeFixedDateLogModel(for: vehicle, name: "Oil Change")
        model.mileageAtService = 30100
        model.applyScheduleDefaults(preset: nil, match: tracked)
        let preview = try XCTUnwrap(model.nextReminderAfterLog)

        let undo = LoggedServiceWriter.save(model, completing: tracked, in: context)

        guard case .completed(_, _, let successor?) = undo.change else {
            return XCTFail("Expected a completion with a successor")
        }
        XCTAssertEqual(successor.dueDate, preview.dueDate)
        XCTAssertEqual(successor.dueMileage, preview.dueMileage)
    }

    func testRecurrenceTurnedOff_NoPreviewAndNoReminderSaved() {
        let vehicle = makeVehicle()
        let model = makeLogModel(for: vehicle, name: "Tire Rotation")
        model.applyScheduleDefaults(
            preset: PresetData(name: "Tire Rotation", category: "Tires", defaultIntervalMonths: 6, defaultIntervalMiles: 5000),
            match: nil
        )
        model.isRecurring = false

        XCTAssertNil(model.nextReminderAfterLog)
        let undo = LoggedServiceWriter.save(model, completing: nil, in: context)
        XCTAssertFalse(undo.leftFutureReminder)
    }

    // MARK: - Mileage adoption (F11)

    func testSave_AdoptedReading_WritesSnapshotAndTimestamp() throws {
        let vehicle = makeVehicle(mileage: 30000)
        let before = vehicle.mileageUpdatedAt
        let model = makeLogModel(for: vehicle, name: "Wiper Blades")
        model.mileageAtService = 30400

        let undo = LoggedServiceWriter.save(model, completing: nil, in: context)

        XCTAssertEqual(vehicle.currentMileage, 30400)
        let updatedAt = try XCTUnwrap(vehicle.mileageUpdatedAt)
        XCTAssertGreaterThan(updatedAt, try XCTUnwrap(before), "Adoption must advance mileageUpdatedAt")
        XCTAssertLessThan(abs(updatedAt.timeIntervalSinceNow), 60, "Stamped with the service date (today)")
        let snapshots = try context.fetch(FetchDescriptor<MileageSnapshot>())
        XCTAssertEqual(snapshots.map(\.mileage), [30400])
        XCTAssertEqual(snapshots.first?.source, .serviceCompletion)
        XCTAssertNotNil(undo.mileageRevert)
    }

    func testSave_ThenUndo_CompletedMatch_RestoresEverything() throws {
        let vehicle = makeVehicle(mileage: 30000)
        let priorUpdatedAt = vehicle.mileageUpdatedAt
        let tracked = makeTrackedService(on: vehicle)
        let prior = ServiceScheduleState(capturing: tracked)
        let model = makeLogModel(for: vehicle)
        model.mileageAtService = 30400
        model.applyScheduleDefaults(preset: nil, match: tracked)

        let undo = LoggedServiceWriter.save(model, completing: tracked, in: context)
        undo.perform(in: context)
        try context.save()

        XCTAssertEqual(ServiceScheduleState(capturing: tracked), prior)
        XCTAssertEqual(try allServices().count, 1)
        XCTAssertTrue(try context.fetch(FetchDescriptor<ServiceLog>()).isEmpty)
        XCTAssertEqual(vehicle.currentMileage, 30000)
        XCTAssertEqual(vehicle.mileageUpdatedAt, priorUpdatedAt)
        XCTAssertTrue(try context.fetch(FetchDescriptor<MileageSnapshot>()).isEmpty)
    }
}
