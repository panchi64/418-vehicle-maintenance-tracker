//
//  AppointmentNoteIntentTests.swift
//  checkpointTests
//
//  Shop appointments and vehicle notes by voice (iOS 26 intents), and the
//  iOS 27 Calendar and Notes schema twins over the same write paths.
//  Cancelling asks first, so nothing is cancelled before a yes.
//

import XCTest
import AppIntents
import SwiftData
@testable import checkpoint

extension ScheduleAppointmentIntent: StoreBackedIntent {}
extension RescheduleAppointmentIntent: StoreBackedIntent {}
extension CancelAppointmentIntent: StoreBackedIntent {}
extension AddVehicleNoteIntent: StoreBackedIntent {}
extension FindNoteIntent: StoreBackedIntent {}
@available(iOS 27, *) extension CreateAppointmentEventIntent: StoreBackedIntent {}
@available(iOS 27, *) extension UpdateAppointmentEventIntent: StoreBackedIntent {}
@available(iOS 27, *) extension CreateVehicleNoteIntent: StoreBackedIntent {}
@available(iOS 27, *) extension UpdateVehicleNoteIntent: StoreBackedIntent {}

final class AppointmentNoteIntentTests: IntentTestCase {

    private var appointments: [Appointment] {
        (try? context.fetch(FetchDescriptor<Appointment>())) ?? []
    }

    private var notes: [VehicleNote] {
        (try? context.fetch(FetchDescriptor<VehicleNote>())) ?? []
    }

    private func inDays(_ days: Double) -> Date { Date(timeIntervalSinceNow: days * 86_400) }

    // MARK: - Schedule

    func test_schedule_booksOnTheShowingVehicle_withServices() async throws {
        let oil = addService("Oil Change")
        let intent = ScheduleAppointmentIntent()
        intent.shop = "Firestone"
        intent.date = inDays(3)
        intent.services = [ServiceEntity(model: oil)]

        _ = try await wired(intent).perform()

        let appointment = try XCTUnwrap(appointments.first)
        XCTAssertEqual(appointment.vehicle?.id, vehicle.id)
        XCTAssertEqual(appointment.shopName, "Firestone")
        XCTAssertEqual(appointment.sortedServices.map(\.id), [oil.id])
    }

    func test_schedule_blankShop_isRefused() {
        XCTAssertThrowsError(try ScheduleAppointmentIntent.book(
            AppointmentFields(shopName: "  ", startDate: inDays(1)), on: vehicle, in: context
        )) { XCTAssertEqual($0 as? IntentError, .appointmentNeedsShop) }
        XCTAssertTrue(appointments.isEmpty)
    }

    // MARK: - Reschedule

    func test_reschedule_noneNamed_movesTheNextOne() async throws {
        let later = try ScheduleAppointmentIntent.book(AppointmentFields(shopName: "Later", startDate: inDays(9)), on: vehicle, in: context)
        let next = try ScheduleAppointmentIntent.book(AppointmentFields(shopName: "Next", startDate: inDays(2)), on: vehicle, in: context)
        let intent = RescheduleAppointmentIntent()
        let target = inDays(4)
        intent.date = target

        _ = try await wired(intent).perform()

        XCTAssertEqual(next.startDate, target)
        XCTAssertEqual(later.startDate.timeIntervalSinceNow, inDays(9).timeIntervalSinceNow, accuracy: 5)
    }

    func test_reschedule_nothingBooked_saysSo() async {
        let intent = RescheduleAppointmentIntent()
        intent.date = inDays(1)
        do {
            _ = try await wired(intent).perform()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? IntentError, .noAppointments)
        }
    }

    // MARK: - Cancel

    func test_cancel_unanswered_cancelsNothing() async throws {
        let appointment = try ScheduleAppointmentIntent.book(AppointmentFields(shopName: "Midas", startDate: inDays(2)), on: vehicle, in: context)
        await runUnanswered { _ = try await self.wired(CancelAppointmentIntent()).perform() }
        XCTAssertEqual(appointment.status, .scheduled)
    }

    func test_cancel_confirmed_cancelsAndKeepsTheRecord() throws {
        let appointment = try ScheduleAppointmentIntent.book(AppointmentFields(shopName: "Midas", startDate: inDays(2)), on: vehicle, in: context)
        try CancelAppointmentIntent.cancel(appointment, in: context)
        XCTAssertEqual(appointment.status, .cancelled)
        XCTAssertEqual(appointments.count, 1)
        XCTAssertThrowsError(try CancelAppointmentIntent.cancel(appointment, in: context)) {
            XCTAssertEqual($0 as? IntentError, .appointmentClosed)
        }
    }

    // MARK: - Notes

    func test_addNote_savesToTheShowingVehicle() async throws {
        let intent = AddVehicleNoteIntent()
        intent.text = "Brake pads at 40 percent"
        intent.isPinned = true

        _ = try await wired(intent).perform()

        let note = try XCTUnwrap(notes.first)
        XCTAssertEqual(note.vehicle?.id, vehicle.id)
        XCTAssertTrue(note.isPinned)
        XCTAssertEqual(note.displayTitle, "Brake pads at 40 percent")
    }

    func test_addNote_empty_isRefused() {
        XCTAssertThrowsError(try AddVehicleNoteIntent.add(VehicleNoteFields(body: " "), to: vehicle, in: context)) {
            XCTAssertEqual($0 as? IntentError, .noteNeedsText)
        }
    }

    func test_findNote_prefersATitleMatch_onTheShowingVehicle() throws {
        let other = Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019)
        context.insert(other)
        VehicleNoteService.create(VehicleNoteFields(title: "Paint code", body: "NH-731P"), on: other, in: context)
        VehicleNoteService.create(VehicleNoteFields(title: "Paint code", body: "B-593P"), on: vehicle, in: context)
        VehicleNoteService.create(VehicleNoteFields(title: "Misc", body: "paint chip on the hood"), on: vehicle, in: context)

        let found = try FindNoteIntent.find("paint", vehicleID: nil, in: context)
        XCTAssertEqual(found.body, "B-593P")
        XCTAssertEqual(try FindNoteIntent.find("paint", vehicleID: other.id, in: context).body, "NH-731P")
        XCTAssertThrowsError(try FindNoteIntent.find("warranty", vehicleID: nil, in: context)) {
            XCTAssertEqual($0 as? IntentError, .noMatchingNote)
        }
    }

    func test_findNote_perform_readsTheFirstLine() async throws {
        VehicleNoteService.create(VehicleNoteFields(title: "Torque", body: "Lug nuts 80 lb-ft\nCheck after 50 mi"), on: vehicle, in: context)
        let intent = FindNoteIntent()
        intent.query = "torque"
        _ = try await wired(intent).perform()
    }

    // MARK: - Routes and entities

    func test_routes_openTheAppointmentAndTheNote() throws {
        let appointment = try ScheduleAppointmentIntent.book(AppointmentFields(shopName: "Midas", startDate: inDays(2)), on: vehicle, in: context)
        let note = VehicleNoteService.create(VehicleNoteFields(title: "Paint"), on: vehicle, in: context)
        XCTAssertEqual(try EntityRoutes.appointment(appointment.id, in: context), .appointment(vehicleID: vehicle.id, appointmentID: appointment.id))
        XCTAssertEqual(try EntityRoutes.vehicleNote(note.id, in: context), .vehicleNote(vehicleID: vehicle.id, noteID: note.id))
    }

    func test_entities_snapshotTheModels() throws {
        let oil = addService("Oil Change")
        let appointment = try ScheduleAppointmentIntent.book(
            AppointmentFields(shopName: "Midas", startDate: inDays(2), serviceIDs: [oil.id]), on: vehicle, in: context
        )
        let entity = try XCTUnwrap(AppointmentEntity.entities(ids: [appointment.id], in: context).first)
        XCTAssertEqual(entity.shopName, "Midas")
        XCTAssertEqual(entity.serviceNames, ["Oil Change"])
        XCTAssertEqual(entity.status, .scheduled)
        XCTAssertEqual(try AppointmentEntity.entities(matching: "oil", in: context).map(\.id), [appointment.id])

        VehicleNoteService.create(VehicleNoteFields(title: "Paint", body: "NH-731P"), on: vehicle, in: context)
        XCTAssertEqual(try VehicleNoteEntity.entities(matching: "731", in: context).first?.title, "Paint")
    }

    // MARK: - iOS 27 Calendar schema

    func test_calendar_createEvent_readsShopAndServicesFromTheTitle() async throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Calendar schema types are iOS 27") }
        let oil = addService("Oil Change")
        let intent = CreateAppointmentEventIntent()
        intent.title = "Oil change at Firestone"
        intent.startDate = inDays(2)
        intent.calendar = VehicleCalendarEntity(model: vehicle)
        intent.location = .address("1 Main St")
        intent.attendees = []
        intent.isAllDay = false

        _ = try await wired(intent).perform()

        let appointment = try XCTUnwrap(appointments.first)
        XCTAssertEqual(appointment.sortedServices.map(\.id), [oil.id])
        XCTAssertEqual(appointment.address, "1 Main St")
    }

    func test_calendar_eventMapping() throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Calendar schema types are iOS 27") }
        let appointment = try ScheduleAppointmentIntent.book(
            AppointmentFields(shopName: "Midas", startDate: inDays(2), address: "2 Calle Loíza", note: "Ask about the rattle"),
            on: vehicle, in: context
        )
        let event = try XCTUnwrap(AppointmentEventEntity.entities(ids: [appointment.id], in: context).first)
        XCTAssertEqual(event.title, "Midas")
        XCTAssertEqual(event.calendar.id, vehicle.id)
        XCTAssertEqual(event.endDate, appointment.effectiveEndDate)
        XCTAssertEqual(event.status, .confirmed)
        XCTAssertEqual(event.alarms.count, 2)
        XCTAssertTrue(event.attendees.isEmpty)
        XCTAssertTrue(event.organizers.isEmpty)
        XCTAssertEqual(event.note.map { String($0.characters) }, "Ask about the rattle")

        AppointmentService.cancel(appointment)
        let cancelled = try XCTUnwrap(AppointmentEventEntity.entities(ids: [appointment.id], in: context).first)
        XCTAssertEqual(cancelled.status, .cancelled)
        XCTAssertTrue(cancelled.alarms.isEmpty)
    }

    func test_calendar_updateEvent_newStartKeepsLength_otherVehicleRefused() async throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Calendar schema types are iOS 27") }
        let appointment = try ScheduleAppointmentIntent.book(
            AppointmentFields(shopName: "Dealer", startDate: inDays(2), endDate: inDays(2).addingTimeInterval(7_200)),
            on: vehicle, in: context
        )
        UpdateAppointmentEventIntent.apply(title: nil, startDate: inDays(5), endDate: nil, note: nil, location: nil, to: appointment)
        XCTAssertEqual(appointment.effectiveEndDate.timeIntervalSince(appointment.startDate), 7_200, accuracy: 1)

        let other = Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019)
        context.insert(other)
        let intent = UpdateAppointmentEventIntent()
        intent.event = AppointmentEventEntity(model: appointment)
        intent.calendar = VehicleCalendarEntity(model: other)
        do {
            _ = try await wired(intent).perform()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? IntentError, .appointmentCannotMove)
        }
    }

    func test_calendarMapping_placeNameWinsAsTheShop() throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Calendar schema types are iOS 27") }
        let place = PlaceDescriptorFixture.firestone
        XCTAssertEqual(CalendarMapping.shopName(title: "Oil change", location: .place(place)), "Firestone")
        XCTAssertEqual(CalendarMapping.shopName(title: " Midas ", location: .address("x")), "Midas")
        XCTAssertEqual(CalendarMapping.place(from: .place(place)).address, "1 Main St")
    }

    // MARK: - iOS 27 Notes schema

    func test_notes_createNote_inTheFolderVehicle() async throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Notes schema types are iOS 27") }
        let other = Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019)
        context.insert(other)
        let intent = CreateVehicleNoteIntent()
        intent.name = AttributedString("Paint code")
        intent.content = AttributedString("NH-731P")
        intent.attachments = []
        intent.isPinned = true
        intent.folder = VehicleFolderEntity(model: other)

        _ = try await wired(intent).perform()

        let note = try XCTUnwrap(notes.first)
        XCTAssertEqual(note.vehicle?.id, other.id)
        XCTAssertEqual(note.title, "Paint code")
        XCTAssertTrue(note.isPinned)
    }

    func test_notes_mapping() throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Notes schema types are iOS 27") }
        XCTAssertEqual(
            NotesMapping.fields(name: AttributedString("Brake pads"), content: AttributedString("Brake pads\n40%"), isPinned: false),
            VehicleNoteFields(title: "", body: "Brake pads\n40%"),
            "A name that only repeats the first line isn't a title"
        )
        XCTAssertEqual(
            NotesMapping.fields(name: AttributedString("Paint"), content: nil, isPinned: true),
            VehicleNoteFields(title: "", body: "Paint", isPinned: true)
        )

        let note = VehicleNoteService.create(VehicleNoteFields(title: "Paint", body: "NH-731P", isPinned: true), on: vehicle, in: context)
        let entity = try XCTUnwrap(VehicleNoteSchemaEntity.entities(ids: [note.id], in: context).first)
        XCTAssertEqual(String(entity.name.characters), "Paint")
        XCTAssertEqual(entity.folder?.id, vehicle.id)
        XCTAssertTrue(entity.isPinned)
    }

    func test_notes_updateNote_renamesAndPins() throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Notes schema types are iOS 27") }
        let note = VehicleNoteService.create(VehicleNoteFields(title: "Old", body: "text"), on: vehicle, in: context)
        try UpdateVehicleNoteIntent.apply(name: "New", isPinned: true, files: [], to: note, in: context)
        XCTAssertEqual(note.title, "New")
        XCTAssertTrue(note.isPinned)
        XCTAssertEqual(note.body, "text", "The schema's update has no content field")
    }
}

import GeoToolbox
import CoreLocation

enum PlaceDescriptorFixture {
    static let firestone = PlaceDescriptor(
        representations: [.address("1 Main St"), .coordinate(CLLocationCoordinate2D(latitude: 18.4, longitude: -66.1))],
        commonName: "Firestone"
    )
}
