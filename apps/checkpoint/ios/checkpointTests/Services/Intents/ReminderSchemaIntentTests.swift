//
//  ReminderSchemaIntentTests.swift
//  checkpointTests
//
//  The iOS 27 Reminders schema types over Checkpoint's services and
//  vehicles: how a service reads as a reminder, and the create / update /
//  delete / create-list writes. Skipped below iOS 27, where the types don't
//  exist.
//

import XCTest
import AppIntents
import SwiftData
@testable import checkpoint

final class ReminderSchemaIntentTests: IntentTestCase {

    private func requireIOS27() throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Reminders schema types are iOS 27") }
    }

    // MARK: - Entities

    func test_reminderEntity_mapsTheService() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let oil = addService("Oil Change", dueInDays: 30, dueMileage: 50_000, intervalMonths: 6, intervalMiles: 5_000)
        oil.notes = "Synthetic only"

        let reminder = ServiceReminderEntity(model: oil)

        XCTAssertEqual(reminder.id, oil.id, "Same UUID as ServiceEntity")
        XCTAssertEqual(reminder.title, "Oil Change")
        XCTAssertEqual(reminder.list.id, vehicle.id)
        XCTAssertEqual(reminder.list.name, vehicle.displayName)
        XCTAssertEqual(reminder.dueDate, ReminderMapping.dueDateComponents(oil.dueDate))
        XCTAssertEqual(reminder.recurrence?.frequency, .monthly)
        XCTAssertEqual(reminder.recurrence?.interval, 6)
        XCTAssertFalse(reminder.isCompleted)
        XCTAssertNil(reminder.completionDate)
        XCTAssertNil(reminder.locationTrigger)
        XCTAssertNil(reminder.isFlagged)
        XCTAssertTrue(reminder.tags.isEmpty)
        let note = String(reminder.note?.characters ?? AttributedString().characters)
        XCTAssertTrue(note.hasPrefix("Synthetic only"))
        XCTAssertTrue(note.contains(L10n.siriReminderNoteDue(Formatters.mileage(50_000))))
        XCTAssertTrue(note.contains(L10n.siriReminderNoteEvery(Formatters.mileage(5_000))))
    }

    func test_reminderEntity_nonRecurringHasNoRecurrence() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let once = addService("Detailing", intervalMonths: 6, isRecurring: false)
        XCTAssertNil(ServiceReminderEntity(model: once).recurrence)
    }

    func test_reminderQuery_skipsOrphans_andListsAreVehicles() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let oil = addService("Oil Change")
        let orphan = Service(name: "Orphan", dueDate: .now)
        context.insert(orphan)
        try context.save()

        let reminders = try ServiceReminderEntity.entities(in: context)
        XCTAssertEqual(reminders.map(\.id), [oil.id])

        let lists = try VehicleListEntity.entities(in: context)
        XCTAssertEqual(lists.map(\.id), [vehicle.id])
        XCTAssertEqual(lists.first?.type, .standard)
    }

    // MARK: - Create

    func test_create_schedulesAServiceWithTheRecurrenceAndNote() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let due = DateComponents(year: 2027, month: 3, day: 1)

        guard case .added(let service) = CreateServiceReminderIntent.add(
            title: "Cabin Filter",
            note: "Buy the charcoal one",
            dueDate: due,
            recurrence: Calendar.RecurrenceRule(calendar: .current, frequency: .yearly),
            to: vehicle,
            in: context
        ) else { return XCTFail("Expected the service to be added") }

        XCTAssertEqual(service.vehicle?.id, vehicle.id)
        XCTAssertEqual(service.dueDate, Calendar.current.date(from: due))
        XCTAssertEqual(service.intervalMonths, 12)
        XCTAssertTrue(service.isRecurring)
        XCTAssertEqual(service.notes, "Buy the charcoal one")
    }

    func test_create_withoutWhen_needsADueDate() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        guard case .needsDue = CreateServiceReminderIntent.add(
            title: "Detailing", note: nil, dueDate: nil, recurrence: nil, to: vehicle, in: context
        ) else { return XCTFail("Expected a due date to be needed") }
        XCTAssertTrue(services.isEmpty)
    }

    // MARK: - Update

    func test_update_completing_logsItLikeMarkDone() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let oil = addService("Oil Change", dueInDays: 3)
        try context.save()

        UpdateServiceReminderIntent.apply(
            ReminderMapping.Update(), completing: true, to: oil, on: vehicle, in: context
        )

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.service?.id, oil.id)
        XCTAssertTrue(ReminderMapping.isCompleted(oil))
        XCTAssertTrue(ServiceReminderEntity(model: oil).isCompleted)
        let next = try XCTUnwrap(ServiceScheduling.trackedService(named: "Oil Change", on: vehicle))
        XCTAssertNotEqual(next.id, oil.id, "The recurrence schedules the next one")
    }

    func test_update_fields_editTheService() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let oil = addService("Oil Change", dueInDays: 3)
        let due = DateComponents(year: 2027, month: 6, day: 15)

        UpdateServiceReminderIntent.apply(
            ReminderMapping.Update(title: "Synthetic Oil Change", dueDate: due),
            completing: false, to: oil, on: vehicle, in: context
        )

        XCTAssertEqual(oil.name, "Synthetic Oil Change")
        XCTAssertEqual(oil.dueDate, Calendar.current.date(from: due))
        XCTAssertTrue(logs.isEmpty, "Editing never logs")
    }

    func test_update_completing_neverWritesWithoutAnAnswer() async throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let oil = addService("Oil Change", dueInDays: 3)
        try context.save()
        let intent = wired(UpdateServiceReminderIntent())
        intent.target = ServiceReminderEntity(model: oil)
        intent.isCompleted = true

        await runUnanswered { _ = try await intent.perform() }

        XCTAssertTrue(logs.isEmpty)
        XCTAssertTrue(oil.hasDueTracking)
    }

    // MARK: - Delete

    func test_delete_neverDeletesWithoutAnAnswer() async throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let oil = addService("Oil Change")
        try context.save()
        let intent = wired(DeleteServiceRemindersIntent())
        intent.entities = [ServiceReminderEntity(model: oil)]

        await runUnanswered { _ = try await intent.perform() }

        XCTAssertEqual(services.count, 1)
    }

    // MARK: - Create list

    func test_createList_addsAVehicle() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        let added = try CreateVehicleListIntent.addVehicle(named: " Weekend Car ", in: context, isPro: false)
        XCTAssertEqual(added.name, "Weekend Car")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Vehicle>()), 2)
    }

    func test_createList_respectsTheFreeLimit() throws {
        try requireIOS27()
        guard #available(iOS 27, *) else { return }
        for index in 1..<VehicleService.freeVehicleLimit {
            context.insert(Vehicle(name: "Car \(index)", make: "", model: "", year: 0, currentMileage: 0))
        }

        XCTAssertThrowsError(try CreateVehicleListIntent.addVehicle(named: "One Too Many", in: context, isPro: false)) {
            XCTAssertEqual($0 as? IntentError, .vehicleLimitReached)
        }
        XCTAssertNoThrow(try CreateVehicleListIntent.addVehicle(named: "Pro Car", in: context, isPro: true))
    }
}
