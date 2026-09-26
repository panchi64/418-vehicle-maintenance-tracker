//
//  VehicleNoteTests.swift
//  checkpointTests
//
//  Vehicle notes: display, order and search; the write path; and the legacy
//  note that mirrors V1's `Vehicle.notes` for older app versions.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class VehicleNoteTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var vehicle: Vehicle!

    override func setUp() {
        super.setUp()
        container = .inMemoryForTesting()
        context = container.mainContext
        vehicle = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020)
        context.insert(vehicle)
    }

    override func tearDown() {
        container = nil
        context = nil
        vehicle = nil
        super.tearDown()
    }

    private var notes: [VehicleNote] {
        (try? context.fetch(FetchDescriptor<VehicleNote>())) ?? []
    }

    // MARK: - Display

    func test_displayTitle_isTheTitle_elseTheFirstLine() {
        XCTAssertEqual(VehicleNote(title: " Paint ", body: "NH-731P").displayTitle, "Paint")
        let untitled = VehicleNote(title: "", body: "\n  Brake pads 40%\nAsk again in June")
        XCTAssertEqual(untitled.displayTitle, "Brake pads 40%")
        XCTAssertEqual(untitled.previewLine, "Ask again in June", "The first line is already the title")
        XCTAssertEqual(VehicleNote(title: "Paint", body: "NH-731P\nx").previewLine, "NH-731P")
    }

    func test_listOrder_pinnedFirst_thenNewest() {
        let old = VehicleNote(title: "old", createdAt: .now.addingTimeInterval(-100))
        let new = VehicleNote(title: "new")
        let pinned = VehicleNote(title: "pinned", isPinned: true, createdAt: .now.addingTimeInterval(-1_000))
        XCTAssertEqual([old, new, pinned].sorted(by: VehicleNote.listOrder).map(\.title), ["pinned", "new", "old"])
    }

    func test_matches_titleBodyOrAttachmentText() {
        let note = VehicleNoteService.create(
            VehicleNoteFields(title: "Quote", body: "Brake pads"),
            attachments: [NoteAttachmentFile(data: Data([1]), fileName: "quote.pdf", mimeType: "application/pdf", extractedText: "Rotor resurfacing $80")],
            on: vehicle,
            in: context
        )
        XCTAssertTrue(note.matches("brake"))
        XCTAssertTrue(note.matches("rotor"))
        XCTAssertTrue(note.matches(""))
        XCTAssertFalse(note.matches("tires"))
    }

    // MARK: - Write path

    func test_create_attachesFilesAsDocumentsOfTheVehicle() {
        let note = VehicleNoteService.create(
            VehicleNoteFields(title: "Scratch", isPinned: true),
            attachments: [NoteAttachmentFile(data: Data([1, 2]), fileName: "scratch.jpg", mimeType: "image/jpeg")],
            on: vehicle,
            in: context
        )
        XCTAssertTrue(note.isPinned)
        let document = try? XCTUnwrap(note.attachments?.first)
        XCTAssertEqual(document?.vehicles?.map(\.id), [vehicle.id], "Shows in the vehicle's library too")
        XCTAssertNil(vehicle.notes, "Only the legacy note mirrors into the field")
    }

    func test_delete_keepsItsFilesInTheLibrary() throws {
        let note = VehicleNoteService.create(
            VehicleNoteFields(title: "Quote"),
            attachments: [NoteAttachmentFile(data: Data([1]), fileName: "q.pdf", mimeType: "application/pdf")],
            on: vehicle,
            in: context
        )
        try context.save()
        VehicleNoteService.delete(note, in: context)
        try context.save()
        Document.purgeOrphans(in: context)

        XCTAssertTrue(notes.isEmpty)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Document>()), 1)
    }

    func test_update_stampsModified() {
        let note = VehicleNoteService.create(VehicleNoteFields(title: "A"), on: vehicle, in: context, now: .distantPast)
        VehicleNoteService.update(note, with: VehicleNoteFields(title: "B"), in: context)
        XCTAssertEqual(note.title, "B")
        XCTAssertGreaterThan(note.modifiedAt, .distantPast)
    }

    // MARK: - Legacy note

    func test_legacyNoteID_isStable_andNeverTheVehicleID() {
        let id = VehicleNoteMigration.legacyNoteID(for: vehicle.id)
        XCTAssertEqual(id, VehicleNoteMigration.legacyNoteID(for: vehicle.id))
        XCTAssertNotEqual(id, vehicle.id)
    }

    func test_reconcile_createsOnce() throws {
        vehicle.notes = "Garage kept"
        try VehicleNoteMigration.reconcile(in: context)
        try VehicleNoteMigration.reconcile(in: context)
        XCTAssertEqual(notes.count, 1)
        XCTAssertTrue(notes[0].isPinned)
    }

    func test_reconcile_keepsTheNewestOfTwoSyncedCopies() throws {
        vehicle.notes = "Garage kept"
        let legacyID = VehicleNoteMigration.legacyNoteID(for: vehicle.id)
        for offset in [-100.0, 0] {
            let copy = VehicleNote(vehicle: vehicle, title: "", body: "Garage kept", isPinned: true, createdAt: .now.addingTimeInterval(offset))
            copy.id = legacyID
            context.insert(copy)
        }
        try VehicleNoteMigration.reconcile(in: context)
        XCTAssertEqual(notes.count, 1)
    }

    func test_reconcile_olderClientEdit_updatesTheNote() throws {
        vehicle.notes = "v1"
        try VehicleNoteMigration.reconcile(in: context)
        vehicle.notes = "v1, edited on an older version"
        try VehicleNoteMigration.reconcile(in: context)
        XCTAssertEqual(notes.first?.body, "v1, edited on an older version")
    }

    func test_reconcile_olderClientClear_removesAPlainNote_keepsOneWithFiles() throws {
        vehicle.notes = "text"
        try VehicleNoteMigration.reconcile(in: context)
        vehicle.notes = nil
        try VehicleNoteMigration.reconcile(in: context)
        XCTAssertTrue(notes.isEmpty)

        vehicle.notes = "text"
        try VehicleNoteMigration.reconcile(in: context)
        VehicleNoteService.update(
            try XCTUnwrap(notes.first),
            with: VehicleNoteFields(note: try XCTUnwrap(notes.first)),
            adding: [NoteAttachmentFile(data: Data([1]), fileName: "a.jpg", mimeType: "image/jpeg")],
            in: context
        )
        vehicle.notes = nil
        try VehicleNoteMigration.reconcile(in: context)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.body, "")
    }

    func test_editingTheLegacyNote_mirrorsIntoTheField() throws {
        vehicle.notes = "old"
        try VehicleNoteMigration.reconcile(in: context)
        let note = try XCTUnwrap(notes.first)
        VehicleNoteService.update(note, with: VehicleNoteFields(title: "", body: "new text", isPinned: true), in: context)
        XCTAssertEqual(vehicle.notes, "new text")

        VehicleNoteService.delete(note, in: context)
        XCTAssertNil(vehicle.notes, "Deleting it clears the field, so an older client doesn't bring it back")
    }

    func test_addVehicle_notesBecomeThePinnedNote() {
        var fields = VehicleFields()
        fields.make = "Mazda"
        fields.model = "MX-5"
        fields.currentMileage = 100
        fields.notes = "Soft top"
        let added = VehicleService.create(fields, in: context)
        XCTAssertEqual(added.vehicleNotes?.first?.body, "Soft top")
        XCTAssertEqual(added.vehicleNotes?.first?.isPinned, true)
    }

    func test_editVehicle_leavesNotesAlone() {
        vehicle.notes = "keep"
        var fields = VehicleFields(vehicle: vehicle)
        fields.notes = ""
        VehicleService.update(vehicle, with: fields, in: context)
        XCTAssertEqual(vehicle.notes, "keep")
    }
}
