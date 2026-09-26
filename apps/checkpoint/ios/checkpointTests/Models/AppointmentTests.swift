//
//  AppointmentTests.swift
//  checkpointTests
//
//  Shop appointments: the time rules, the write path, what Log Visit opens
//  with, the reminders it builds (pure — the test host has no notification
//  authorization) and the place Maps is handed.
//

import XCTest
import AppIntents
import GeoToolbox
import SwiftData
import UserNotifications
@testable import checkpoint

@MainActor
final class AppointmentTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var vehicle: Vehicle!
    var oil: Service!
    var tires: Service!

    private let calendar = Calendar.current
    private let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 14))!

    override func setUp() {
        super.setUp()
        container = .inMemoryForTesting()
        context = container.mainContext
        vehicle = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020)
        context.insert(vehicle)
        oil = Service(name: "Oil Change")
        oil.vehicle = vehicle
        tires = Service(name: "Tire Rotation")
        tires.vehicle = vehicle
        context.insert(oil)
        context.insert(tires)
    }

    override func tearDown() {
        container = nil
        context = nil
        vehicle = nil
        oil = nil
        tires = nil
        super.tearDown()
    }

    private func hours(_ h: Double) -> Date { now.addingTimeInterval(h * 3600) }

    @discardableResult
    private func book(_ shop: String = "Firestone", at start: Date? = nil, services: [Service] = []) -> Appointment {
        AppointmentService.schedule(
            AppointmentFields(shopName: shop, startDate: start ?? hours(48), serviceIDs: services.map(\.id)),
            on: vehicle,
            in: context
        )
    }

    // MARK: - Time rules

    func test_newBooking_defaultsToTomorrowAtNine() {
        let fields = AppointmentFields.newBooking(now: now)
        let parts = calendar.dateComponents([.day, .hour, .minute], from: fields.startDate)
        XCTAssertEqual(parts.day, 27)
        XCTAssertEqual(parts.hour, 9)
        XCTAssertEqual(parts.minute, 0)
        XCTAssertFalse(fields.isValid, "No shop yet")
    }

    func test_effectiveEnd_defaultsToAnHour() {
        let appointment = book(at: hours(5))
        XCTAssertEqual(appointment.effectiveEndDate, hours(6))
    }

    func test_timing() {
        XCTAssertEqual(book(at: hours(3)).timing(now: now), .today)
        XCTAssertEqual(book(at: hours(24)).timing(now: now), .inDays(1))
        XCTAssertEqual(book(at: hours(24 * 5)).timing(now: now), .inDays(5))
        XCTAssertEqual(book(at: hours(-2.5)).timing(now: now), .started(hoursAgo: 2))
    }

    func test_reminderDates_dayBeforeAndHourBefore_droppingPast() {
        XCTAssertEqual(Appointment.reminderDates(for: hours(48), now: now), [.dayBefore: hours(24), .hourBefore: hours(47)])
        XCTAssertEqual(Appointment.reminderDates(for: hours(5), now: now), [.hourBefore: hours(4)])
        XCTAssertTrue(Appointment.reminderDates(for: hours(0.5), now: now).isEmpty)
    }

    func test_scheduled_soonestFirst_withoutClosed() {
        let later = book("B", at: hours(72))
        let sooner = book("A", at: hours(24))
        let cancelled = book("C", at: hours(1))
        AppointmentService.cancel(cancelled)
        XCTAssertEqual(Appointment.scheduled([later, sooner, cancelled]).map(\.shopName), ["A", "B"])
    }

    func test_sameDay_findsOthers_notItself() {
        let first = book("Midas", at: hours(20))
        let second = book("Firestone", at: hours(22))
        XCTAssertEqual(Appointment.sameDay(as: hours(21), in: [first, second], excluding: second.id).map(\.id), [first.id])
    }

    // MARK: - Write path

    func test_schedule_linksOnlyThisVehiclesServices() {
        let foreign = Service(name: "Foreign")
        context.insert(foreign)
        let appointment = AppointmentService.schedule(
            AppointmentFields(shopName: "  Firestone ", startDate: hours(24), serviceIDs: [oil.id, foreign.id]),
            on: vehicle,
            in: context
        )
        XCTAssertEqual(appointment.shopName, "Firestone")
        XCTAssertEqual(appointment.sortedServices.map(\.id), [oil.id])
        XCTAssertEqual(oil.appointments?.map(\.id), [appointment.id], "The inverse is set")
        XCTAssertTrue(appointment.isScheduled)
    }

    func test_reschedule_keepsTheLength() {
        let appointment = AppointmentService.schedule(
            AppointmentFields(shopName: "Dealer", startDate: hours(24), endDate: hours(27)),
            on: vehicle,
            in: context
        )
        AppointmentService.reschedule(appointment, to: hours(48))
        XCTAssertEqual(appointment.startDate, hours(48))
        XCTAssertEqual(appointment.endDate, hours(51))
    }

    func test_editingTheAddress_dropsTheOldCoordinate() {
        let appointment = AppointmentService.schedule(
            AppointmentFields(shopName: "Dealer", startDate: hours(24), address: "1 Main St", latitude: 18.4, longitude: -66.1),
            on: vehicle,
            in: context
        )
        XCTAssertEqual(appointment.latitude, 18.4)
        var fields = AppointmentFields(appointment: appointment)
        fields.address = "2 Other Rd"
        AppointmentService.update(appointment, with: fields)
        XCTAssertNil(appointment.latitude)
        XCTAssertEqual(appointment.address, "2 Other Rd")
    }

    func test_cancelAndComplete_close() {
        let cancelled = book()
        AppointmentService.cancel(cancelled, now: now)
        XCTAssertEqual(cancelled.status, .cancelled)
        XCTAssertEqual(cancelled.closedAt, now)

        let done = book()
        AppointmentService.markCompleted(done, now: now)
        XCTAssertEqual(done.status, .completed)
    }

    func test_deletingAVehicle_takesItsAppointments() throws {
        book()
        try context.save()
        context.delete(vehicle)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Appointment>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Service>()), 0)
    }

    // MARK: - Log Visit

    func test_completion_withServices_opensTheVisitForm_onTheAppointmentsDay() {
        let appointment = book(at: hours(-3), services: [tires, oil])
        let completion = AppointmentCompletion(appointment: appointment, now: now)
        guard case .visit(let services) = completion.form else { return XCTFail("Expected the visit form") }
        XCTAssertEqual(services.map(\.name), ["Oil Change", "Tire Rotation"])
        XCTAssertEqual(completion.performedDate, hours(-3))
        XCTAssertEqual(completion.visitPrefill, VisitPrefill(performedDate: hours(-3), shopName: "Firestone"))
    }

    func test_completion_aheadOfTime_isDatedToday() {
        let completion = AppointmentCompletion(appointment: book(at: hours(30)), now: now)
        XCTAssertEqual(completion.performedDate, now, "A log can't be dated in the future")
    }

    func test_completion_withoutServices_opensTheLogDoor() {
        let completion = AppointmentCompletion(appointment: book(), now: now)
        guard case .log = completion.form else { return XCTFail("Expected the log door") }
    }

    func test_completion_dropsServicesNoLongerTracked() throws {
        let appointment = book(services: [oil])
        context.delete(oil)
        try context.save()
        guard case .log = AppointmentCompletion(appointment: appointment, now: now).form else {
            return XCTFail("A deleted service drops out")
        }
    }

    func test_logDoorPrefill_showsAndSavesTheShop() {
        let model = ServiceLogFormModel(vehicle: vehicle, mode: .log)
        model.apply(visit: VisitPrefill(performedDate: now.addingTimeInterval(-86_400 * 3), shopName: "Midas"), now: now)
        XCTAssertTrue(model.showsShopField)
        XCTAssertEqual(model.timing, .earlier)
        XCTAssertEqual(model.receiptVisitDetails?.shopName, "Midas", "The shop goes on a visit on save")
    }

    // MARK: - Reminders

    func test_reminderRequests_twoPerBooking_taggedAndRouted() throws {
        let appointment = book(at: hours(48))
        let requests = AppointmentNotificationScheduler.requests(for: appointment, now: now)
        XCTAssertEqual(requests.map(\.identifier), [
            AppointmentNotificationScheduler.requestID(appointmentID: appointment.id, lead: .dayBefore),
            AppointmentNotificationScheduler.requestID(appointmentID: appointment.id, lead: .hourBefore),
        ])
        let first = try XCTUnwrap(requests.first)
        XCTAssertEqual(first.content.title, L10n.notificationAppointmentTitleTomorrow)
        XCTAssertTrue(first.content.body.contains("Firestone"))
        XCTAssertTrue(first.content.body.hasPrefix(vehicle.displayName), "The vehicle speaks (NOTIFICATION_TONE)")
        XCTAssertEqual(first.content.userInfo["appointmentID"] as? String, appointment.id.uuidString)
        let trigger = try XCTUnwrap(first.trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(trigger.nextTriggerDate(), hours(24))
    }

    func test_reminderRequests_noneWhenClosedOrPast() {
        let cancelled = book()
        AppointmentService.cancel(cancelled)
        XCTAssertTrue(AppointmentNotificationScheduler.requests(for: cancelled, now: now).isEmpty)
        XCTAssertTrue(AppointmentNotificationScheduler.requests(for: book(at: hours(-1)), now: now).isEmpty)
    }

    func test_orphanDetection() {
        let id = UUID()
        let request = AppointmentNotificationScheduler.requestID(appointmentID: id, lead: .hourBefore)
        XCTAssertFalse(AppointmentNotificationScheduler.isOrphaned(identifier: request, scheduledIDs: [id]))
        XCTAssertTrue(AppointmentNotificationScheduler.isOrphaned(identifier: request, scheduledIDs: []))
        XCTAssertFalse(AppointmentNotificationScheduler.isOrphaned(identifier: "service-x", scheduledIDs: []))
    }

    func test_reminder_isTaggedWithTheAppointmentAndVehicle() throws {
        // A method-level @available doesn't stop XCTest running it on 26.
        guard #available(iOS 27, *) else { throw XCTSkip("Notification entity tags are iOS 27") }
        let appointment = book(at: hours(48))
        let content = try XCTUnwrap(AppointmentNotificationScheduler.requests(for: appointment, now: now).first).content
        let tags = (content.mutableCopy() as? UNMutableNotificationContent)?.appEntityIdentifiers
        XCTAssertEqual(tags?.count, 3, "AppointmentEntity, its Calendar event, the vehicle")
    }

    // MARK: - Directions

    func test_place_coordinateAndAddress_namedForTheShop() throws {
        let appointment = AppointmentService.schedule(
            AppointmentFields(shopName: "Dealer", startDate: hours(24), address: "1 Main St", latitude: 18.4, longitude: -66.1),
            on: vehicle,
            in: context
        )
        let place = try XCTUnwrap(AppointmentDirections.placeDescriptor(for: appointment))
        XCTAssertEqual(place.commonName, "Dealer")
        XCTAssertEqual(place.address, "1 Main St")
        XCTAssertEqual(place.coordinate?.latitude, 18.4)
    }

    func test_place_shopNameOnly_searchesByName() {
        let appointment = book("Firestone Hato Rey")
        XCTAssertNil(AppointmentDirections.placeDescriptor(for: appointment))
        XCTAssertEqual(AppointmentDirections.searchQuery(for: appointment), "Firestone Hato Rey")
    }
}
