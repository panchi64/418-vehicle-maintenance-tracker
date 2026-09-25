//
//  ServiceLogDeletionTests.swift
//  checkpointTests
//
//  Deleting a log must recompute what was derived from it — the parent
//  service's last-performed values, a successor reminder anchored on it, an
//  emptied visit — and the returned snapshot must undo all of it.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceLogDeletionTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self,
                ServiceVisit.self, VisitLineItem.self, MileageSnapshot.self,
                ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeVehicle() -> Vehicle {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, currentMileage: 20000)
        modelContext.insert(vehicle)
        return vehicle
    }

    /// A completed (closed) occurrence: no schedule, one log — the shape
    /// `ServiceCompletionService` leaves behind.
    @discardableResult
    private func closedOccurrence(
        _ name: String,
        on performed: Date,
        at mileage: Int,
        vehicle: Vehicle
    ) -> ServiceLog {
        let service = Service(name: name, lastPerformed: performed, lastMileage: mileage)
        service.vehicle = vehicle
        modelContext.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: performed, mileageAtService: mileage)
        modelContext.insert(log)
        return log
    }

    /// The spawned successor, due derived from `anchor` exactly as completion does.
    private func successor(_ name: String, anchoredOn anchor: ServiceLog, vehicle: Vehicle) -> Service {
        let next = Service(name: name, intervalMonths: 6, intervalMiles: 5000, isRecurring: true)
        next.vehicle = vehicle
        next.deriveDueFromIntervals(anchorDate: anchor.performedDate, anchorMileage: anchor.mileageAtService)
        modelContext.insert(next)
        return next
    }

    private func fetchLogs() throws -> [ServiceLog] {
        try modelContext.fetch(FetchDescriptor<ServiceLog>())
    }

    // MARK: - Parent service

    func test_delete_parentLastPerformedMovesToNewestRemainingLog() throws {
        let vehicle = makeVehicle()
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        modelContext.insert(service)
        let older = ServiceLog(service: service, vehicle: vehicle, performedDate: date(2025, 1, 10), mileageAtService: 10000)
        let newer = ServiceLog(service: service, vehicle: vehicle, performedDate: date(2025, 7, 10), mileageAtService: 15000)
        modelContext.insert(older)
        modelContext.insert(newer)
        service.lastPerformed = newer.performedDate
        service.lastMileage = newer.mileageAtService
        try modelContext.save()

        ServiceLogDeletion.delete(newer, in: modelContext)
        try modelContext.save()

        XCTAssertEqual(service.lastPerformed, date(2025, 1, 10))
        XCTAssertEqual(service.lastMileage, 10000)
        XCTAssertEqual(try fetchLogs().map(\.id), [older.id])
    }

    func test_delete_onlyLog_clearsLastPerformedButKeepsService() throws {
        let vehicle = makeVehicle()
        let log = closedOccurrence("Wipers", on: date(2025, 3, 1), at: 12000, vehicle: vehicle)
        let service = try XCTUnwrap(log.service)
        try modelContext.save()

        ServiceLogDeletion.delete(log, in: modelContext)
        try modelContext.save()

        XCTAssertNil(service.lastPerformed)
        XCTAssertNil(service.lastMileage)
        XCTAssertFalse(service.isDeleted, "A service is never deleted with its last log")
        XCTAssertTrue(try fetchLogs().isEmpty)
    }

    // MARK: - Next due

    func test_delete_completionLog_reanchorsSuccessorOnPreviousLog() throws {
        let vehicle = makeVehicle()
        closedOccurrence("Oil Change", on: date(2025, 1, 10), at: 10000, vehicle: vehicle)
        let latest = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        let next = successor("Oil Change", anchoredOn: latest, vehicle: vehicle)
        try modelContext.save()
        XCTAssertEqual(next.dueMileage, 20000)

        ServiceLogDeletion.delete(latest, in: modelContext)
        try modelContext.save()

        XCTAssertEqual(next.dueDate, date(2025, 7, 10), "Six months from the remaining Jan 10 log")
        XCTAssertEqual(next.dueMileage, 15000, "5,000 mi from the remaining 10,000 mi log")
    }

    func test_delete_completionLog_reanchorMatchesNameCaseInsensitively() throws {
        let vehicle = makeVehicle()
        closedOccurrence("oil change", on: date(2025, 1, 10), at: 10000, vehicle: vehicle)
        let latest = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        let next = successor("Oil Change ", anchoredOn: latest, vehicle: vehicle)
        try modelContext.save()

        ServiceLogDeletion.delete(latest, in: modelContext)

        XCTAssertEqual(next.dueMileage, 15000)
    }

    func test_delete_onlyLogOfName_leavesSuccessorReminderInPlace() throws {
        let vehicle = makeVehicle()
        let only = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        let next = successor("Oil Change", anchoredOn: only, vehicle: vehicle)
        let dueDate = next.dueDate
        try modelContext.save()

        ServiceLogDeletion.delete(only, in: modelContext)

        XCTAssertEqual(next.dueDate, dueDate, "With nothing to re-anchor on, the reminder the user has stays")
        XCTAssertEqual(next.dueMileage, 20000)
    }

    func test_delete_leavesHandEditedReminderAlone() throws {
        let vehicle = makeVehicle()
        closedOccurrence("Oil Change", on: date(2025, 1, 10), at: 10000, vehicle: vehicle)
        let latest = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        let next = successor("Oil Change", anchoredOn: latest, vehicle: vehicle)
        next.dueMileage = 22000 // user override
        try modelContext.save()

        ServiceLogDeletion.delete(latest, in: modelContext)

        XCTAssertEqual(next.dueMileage, 22000)
        XCTAssertEqual(next.dueDate, date(2026, 1, 10))
    }

    func test_delete_olderLog_doesNotMoveReminder() throws {
        let vehicle = makeVehicle()
        let older = closedOccurrence("Oil Change", on: date(2025, 1, 10), at: 10000, vehicle: vehicle)
        let latest = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        let next = successor("Oil Change", anchoredOn: latest, vehicle: vehicle)
        try modelContext.save()

        ServiceLogDeletion.delete(older, in: modelContext)

        XCTAssertEqual(next.dueDate, date(2026, 1, 10))
        XCTAssertEqual(next.dueMileage, 20000)
    }

    func test_delete_otherServiceNameIsUntouched() throws {
        let vehicle = makeVehicle()
        let oil = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        closedOccurrence("Tire Rotation", on: date(2025, 1, 10), at: 10000, vehicle: vehicle)
        let rotation = successor("Tire Rotation", anchoredOn: oil, vehicle: vehicle)
        try modelContext.save()

        ServiceLogDeletion.delete(oil, in: modelContext)

        XCTAssertEqual(rotation.dueMileage, 20000)
    }

    func test_delete_recurringLogModeService_reanchorsItsOwnDue() throws {
        // Record Service with Repeats on: one Service carries both the log and
        // the reminder derived from it.
        let vehicle = makeVehicle()
        let service = Service(name: "Oil Change", intervalMonths: 6, intervalMiles: 5000, isRecurring: true)
        service.vehicle = vehicle
        modelContext.insert(service)
        let older = ServiceLog(service: service, vehicle: vehicle, performedDate: date(2025, 1, 10), mileageAtService: 10000)
        let newer = ServiceLog(service: service, vehicle: vehicle, performedDate: date(2025, 7, 10), mileageAtService: 15000)
        modelContext.insert(older)
        modelContext.insert(newer)
        service.recalculateDueDates(performedDate: newer.performedDate, mileage: newer.mileageAtService)
        try modelContext.save()

        ServiceLogDeletion.delete(newer, in: modelContext)

        XCTAssertEqual(service.lastPerformed, date(2025, 1, 10))
        XCTAssertEqual(service.dueDate, date(2025, 7, 10))
        XCTAssertEqual(service.dueMileage, 15000)
    }

    // MARK: - Visits

    func test_delete_logWithVisitSiblings_keepsVisitAndTotal() throws {
        let vehicle = makeVehicle()
        let visit = ServiceVisit(vehicle: vehicle, performedDate: date(2025, 7, 10), mileageAtVisit: 15000, totalCost: 300)
        modelContext.insert(visit)
        let oil = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        let rotation = closedOccurrence("Tire Rotation", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        oil.visit = visit
        rotation.visit = visit
        try modelContext.save()

        ServiceLogDeletion.delete(oil, in: modelContext)
        try modelContext.save()

        XCTAssertFalse(visit.isDeleted)
        XCTAssertEqual(visit.totalCost, 300)
        XCTAssertEqual(visit.logs?.map(\.id), [rotation.id])
    }

    func test_delete_lastLogOfVisit_deletesVisit() throws {
        let vehicle = makeVehicle()
        let visit = ServiceVisit(vehicle: vehicle, performedDate: date(2025, 7, 10), mileageAtVisit: 15000, totalCost: 300)
        modelContext.insert(visit)
        let oil = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        oil.visit = visit
        try modelContext.save()

        ServiceLogDeletion.delete(oil, in: modelContext)
        try modelContext.save()

        XCTAssertTrue(try modelContext.fetch(FetchDescriptor<ServiceVisit>()).isEmpty)
    }

    // MARK: - Attachments

    func test_delete_keepsAttachmentsInDocumentLibrary() throws {
        let vehicle = makeVehicle()
        let log = closedOccurrence("Brakes", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        let receipt = ServiceAttachment(serviceLog: log, fileName: "receipt.jpg", mimeType: "image/jpeg", vehicles: [])
        modelContext.insert(receipt)
        try modelContext.save()

        ServiceLogDeletion.delete(log, in: modelContext)
        try modelContext.save()

        XCTAssertFalse(receipt.isDeleted)
        XCTAssertNil(receipt.serviceLog)
        XCTAssertEqual(receipt.vehicles?.map(\.id), [vehicle.id], "Linked to the vehicle so the orphan sweep keeps it")
    }

    // MARK: - Undo

    func test_undo_restoresLogScheduleAndLinks() throws {
        let vehicle = makeVehicle()
        closedOccurrence("Oil Change", on: date(2025, 1, 10), at: 10000, vehicle: vehicle)
        let latest = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        latest.cost = 49
        latest.costCategory = .maintenance
        latest.notes = "Synthetic"
        let parent = try XCTUnwrap(latest.service)
        let receipt = ServiceAttachment(serviceLog: latest, fileName: "r.jpg", mimeType: "image/jpeg")
        modelContext.insert(receipt)
        let next = successor("Oil Change", anchoredOn: latest, vehicle: vehicle)
        let logID = latest.id
        try modelContext.save()

        let deletion = ServiceLogDeletion.delete(latest, in: modelContext)
        try modelContext.save()
        let restored = deletion.undo(in: modelContext)
        try modelContext.save()

        XCTAssertEqual(restored.id, logID)
        XCTAssertEqual(restored.performedDate, date(2025, 7, 10))
        XCTAssertEqual(restored.mileageAtService, 15000)
        XCTAssertEqual(restored.cost, 49)
        XCTAssertEqual(restored.costCategory, .maintenance)
        XCTAssertEqual(restored.notes, "Synthetic")
        XCTAssertEqual(restored.service?.id, parent.id)
        XCTAssertEqual(restored.vehicle?.id, vehicle.id)
        XCTAssertEqual(receipt.serviceLog?.id, logID)

        XCTAssertEqual(parent.lastPerformed, date(2025, 7, 10))
        XCTAssertEqual(parent.lastMileage, 15000)
        XCTAssertEqual(next.dueDate, date(2026, 1, 10))
        XCTAssertEqual(next.dueMileage, 20000)
        XCTAssertEqual(try fetchLogs().count, 2)
    }

    func test_undo_recreatesDeletedVisitWithLineItems() throws {
        let vehicle = makeVehicle()
        let visit = ServiceVisit(
            vehicle: vehicle,
            performedDate: date(2025, 7, 10),
            mileageAtVisit: 15000,
            totalCost: 300,
            costCategory: .repair,
            isItemized: false,
            shopName: "Bob's"
        )
        modelContext.insert(visit)
        let labor = VisitLineItem(visit: visit, label: "Labor", kind: .labor, amount: 120)
        modelContext.insert(labor)
        let visitID = visit.id
        let oil = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        oil.visit = visit
        try modelContext.save()

        let deletion = ServiceLogDeletion.delete(oil, in: modelContext)
        try modelContext.save()
        let restored = deletion.undo(in: modelContext)
        try modelContext.save()

        let restoredVisit = try XCTUnwrap(restored.visit)
        XCTAssertEqual(restoredVisit.id, visitID)
        XCTAssertEqual(restoredVisit.totalCost, 300)
        XCTAssertEqual(restoredVisit.costCategory, .repair)
        XCTAssertEqual(restoredVisit.shopName, "Bob's")
        XCTAssertEqual(restoredVisit.lineItems?.map(\.label), ["Labor"])
        XCTAssertEqual(restoredVisit.lineItems?.first?.amount, 120)
        XCTAssertEqual(try modelContext.fetch(FetchDescriptor<ServiceVisit>()).count, 1)
    }

    func test_undo_relinksToSurvivingVisit() throws {
        let vehicle = makeVehicle()
        let visit = ServiceVisit(vehicle: vehicle, performedDate: date(2025, 7, 10), mileageAtVisit: 15000, totalCost: 300)
        modelContext.insert(visit)
        let oil = closedOccurrence("Oil Change", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        let rotation = closedOccurrence("Tire Rotation", on: date(2025, 7, 10), at: 15000, vehicle: vehicle)
        oil.visit = visit
        rotation.visit = visit
        try modelContext.save()

        let deletion = ServiceLogDeletion.delete(oil, in: modelContext)
        try modelContext.save()
        let restored = deletion.undo(in: modelContext)
        try modelContext.save()

        XCTAssertEqual(restored.visit?.id, visit.id)
        XCTAssertEqual(visit.logs?.count, 2)
    }
}
