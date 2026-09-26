//
//  ServiceLoggingIntentTests.swift
//  checkpointTests
//
//  Mark Done and Log Service by voice write what the app's forms write:
//  completing a tracked service chains it forward, a name matching one on
//  the schedule completes it instead of duplicating it, a shop or several
//  services make one visit with one total, and nothing is written before
//  Siri hears a yes.
//

import XCTest
import SwiftData
@testable import checkpoint

final class ServiceLoggingIntentTests: IntentTestCase {

    // MARK: - Mark done

    func test_markDone_recurring_logsAndSpawnsNextOccurrence() throws {
        let oil = addService("Oil Change", dueInDays: 3)
        try context.save()

        let logs = ServiceLogging.markDone(
            oil, on: vehicle,
            occasion: ServiceLogging.Occasion(mileage: 45_300, totalCost: 59.99),
            in: context
        )

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs[0].cost, Decimal(string: "59.99"))
        XCTAssertEqual(logs[0].mileageAtService, 45_300)
        XCTAssertNil(logs[0].visit, "No shop, no visit — the in-app Mark Done shape")
        XCTAssertFalse(oil.hasDueTracking, "The completed occurrence closes")
        let next = try XCTUnwrap(ServiceScheduling.trackedService(named: "Oil Change", on: vehicle))
        XCTAssertNotEqual(next.id, oil.id)
        XCTAssertEqual(vehicle.currentMileage, 45_300, "A newer reading is adopted (F11)")
    }

    func test_markDone_withShop_writesOneVisit() {
        let oil = addService("Oil Change", dueInDays: 3)

        let logs = ServiceLogging.markDone(
            oil, on: vehicle,
            occasion: ServiceLogging.Occasion(totalCost: 80, shop: "  Firestone "),
            in: context
        )

        let visit = logs.first?.visit
        XCTAssertEqual(visit?.shopName, "Firestone")
        XCTAssertEqual(visit?.totalCost, 80)
        XCTAssertNil(logs.first?.cost, "The visit owns the total")
        XCTAssertEqual(visit?.mileageAtVisit, 45_000, "No odometer said: the reading on file")
    }

    func test_markDone_defaultsToTodayAndTheReadingOnFile() {
        let oil = addService("Oil Change", dueInDays: 3)
        let log = ServiceLogging.markDone(oil, on: vehicle, occasion: .init(), in: context)[0]

        XCTAssertTrue(Calendar.current.isDateInToday(log.performedDate))
        XCTAssertEqual(log.mileageAtService, 45_000)
        XCTAssertNil(log.cost)
    }

    func test_markDoneIntent_occasion_convertsKilometers() {
        DistanceSettings.shared.unit = .kilometers
        let intent = MarkServiceDoneIntent()
        intent.mileage = 73_000
        XCTAssertEqual(intent.occasion.mileage, DistanceUnit.kilometers.toMiles(73_000))
    }

    func test_markDoneIntent_savedDialog_namesTheNextDue() {
        let oil = addService("Oil Change", dueInDays: 3)
        ServiceLogging.markDone(oil, on: vehicle, occasion: .init(), in: context)

        let dialog = MarkServiceDoneIntent.savedDialog(for: oil, vehicle: vehicle)
        let next = ServiceScheduling.trackedService(named: "Oil Change", on: vehicle)!
        XCTAssertTrue(dialog.contains(SpokenValue.date(next.dueDate!)), dialog)
    }

    func test_markDoneIntent_neverWritesWithoutAnAnswer() async throws {
        let oil = addService("Oil Change", dueInDays: 3)
        try context.save()
        let intent = MarkServiceDoneIntent(service: ServiceEntity(model: oil))

        await runUnanswered { _ = try await self.wired(intent).perform() }

        XCTAssertTrue(oil.hasDueTracking)
        XCTAssertTrue(logs.isEmpty)
    }

    func test_markDoneFromSnippet_completesWithFormDefaults() async throws {
        let oil = addService("Oil Change", dueInDays: -2)
        try context.save()

        _ = try await wired(MarkDoneFromSnippetIntent(service: ServiceEntity(model: oil))).perform()

        XCTAssertFalse(oil.hasDueTracking)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.mileageAtService, 45_000)
        XCTAssertFalse(context.hasChanges)
    }

    // MARK: - Log

    func test_log_nameMatchingTrackedService_completesIt() {
        let rotation = addService("Tire Rotation", dueInDays: 10)

        let logs = ServiceLogging.log(["tire rotation"], on: vehicle, occasion: .init(), in: context)

        XCTAssertEqual(logs.first?.service?.id, rotation.id, "Completes the tracked service, no duplicate")
        XCTAssertFalse(rotation.hasDueTracking)
    }

    func test_log_presetName_createsRecurringService() throws {
        let logs = ServiceLogging.log(["oil change"], on: vehicle, occasion: .init(), in: context)

        let service = try XCTUnwrap(logs.first?.service)
        XCTAssertEqual(service.name, "Oil Change", "Takes the preset's name")
        XCTAssertTrue(service.isRecurring, "A preset's cadence starts a reminder from today")
        XCTAssertTrue(service.hasDueTracking)
    }

    func test_log_backfilledPreset_doesNotStartAReminder() throws {
        let longAgo = Calendar.current.date(byAdding: .month, value: -8, to: .now)!
        let logs = ServiceLogging.log(
            ["Oil Change", "Wiper Blades"], on: vehicle,
            occasion: .init(date: longAgo), in: context
        )

        XCTAssertEqual(logs.count, 2)
        XCTAssertTrue(logs.allSatisfy { $0.service?.hasDueTracking == false })
    }

    func test_log_severalServices_oneVisitOneTotal() throws {
        addService("Oil Change", dueInDays: 3)

        let logs = ServiceLogging.log(
            ["Oil Change", "Cabin Air Filter"], on: vehicle,
            occasion: .init(mileage: 45_200, totalCost: 120, shop: "Firestone"),
            in: context
        )

        XCTAssertEqual(logs.count, 2)
        let visit = try XCTUnwrap(logs.first?.visit)
        XCTAssertTrue(logs.allSatisfy { $0.visit === visit })
        XCTAssertEqual(visit.totalCost, 120)
        XCTAssertEqual(visit.shopName, "Firestone")
        XCTAssertTrue(logs.allSatisfy { $0.cost == nil }, "Never the total divided per service")
        XCTAssertEqual(vehicle.currentMileage, 45_200)
    }

    func test_names_splitsSpokenLists_butKeepsKnownNames() {
        let known: Set<String> = ["Oil Change", "Brake Pads and Rotors"]
        XCTAssertEqual(
            ServiceLogging.names(in: ["oil change and tire rotation"], knownNames: known),
            ["oil change", "tire rotation"]
        )
        XCTAssertEqual(
            ServiceLogging.names(in: ["cambio de aceite y filtro, gomas"], knownNames: known),
            ["cambio de aceite", "filtro", "gomas"]
        )
        XCTAssertEqual(
            ServiceLogging.names(in: ["brake pads and rotors"], knownNames: known),
            ["brake pads and rotors"]
        )
        XCTAssertEqual(
            ServiceLogging.names(in: ["Oil Change", "oil change", "  "], knownNames: known),
            ["Oil Change"]
        )
    }

    func test_timing_mapsSpokenDatesToTheFormsTimings() {
        let now = Date()
        let calendar = Calendar.current
        XCTAssertEqual(ServiceLogging.timing(for: nil, now: now), .today)
        XCTAssertEqual(ServiceLogging.timing(for: now.addingTimeInterval(-60), now: now), .today)
        XCTAssertEqual(ServiceLogging.timing(for: calendar.date(byAdding: .day, value: -1, to: now), now: now), .yesterday)
        XCTAssertEqual(ServiceLogging.timing(for: calendar.date(byAdding: .day, value: -9, to: now), now: now), .earlier)
        XCTAssertEqual(ServiceLogging.timing(for: calendar.date(byAdding: .day, value: 2, to: now), now: now), .today)
    }

    func test_logServiceIntent_neverWritesWithoutAnAnswer() async {
        let intent = LogServiceIntent()
        intent.services = ["Oil Change"]

        await runUnanswered { _ = try await self.wired(intent).perform() }

        XCTAssertTrue(logs.isEmpty)
    }
}
