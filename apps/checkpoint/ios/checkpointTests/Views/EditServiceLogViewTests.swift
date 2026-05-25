//
//  EditServiceLogViewTests.swift
//  checkpointTests
//
//  Tests for EditServiceLogView — edit notes and add attachments to a service log
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class EditServiceLogViewTests: XCTestCase {

    // MARK: - Notes Loading Tests

    func testNotesLoading_ExistingNotesPreserved() {
        // Given: A service log with notes
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000,
            notes: "Synthetic 0W-20 oil"
        )

        // Then: Notes should be accessible
        XCTAssertEqual(log.notes, "Synthetic 0W-20 oil")
    }

    func testNotesLoading_NilNotesHandled() {
        // Given: A service log without notes
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000
        )

        // Then: Notes should be nil
        XCTAssertNil(log.notes)
    }

    // MARK: - Notes Update Tests

    func testNotesUpdate_EmptyBecomesNil() {
        // Given: Empty notes string
        let notes = ""

        // When: Converting for save
        let notesValue: String? = notes.isEmpty ? nil : notes

        // Then: Should be nil
        XCTAssertNil(notesValue)
    }

    func testNotesUpdate_NonEmptyPreserved() {
        // Given: Non-empty notes string
        let notes = "Changed to synthetic oil"

        // When: Converting for save
        let notesValue: String? = notes.isEmpty ? nil : notes

        // Then: Should preserve value
        XCTAssertEqual(notesValue, "Changed to synthetic oil")
    }

    func testNotesUpdate_CanClearExistingNotes() {
        // Given: A log with existing notes
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000,
            notes: "Original notes"
        )

        // When: Clearing notes
        log.notes = nil

        // Then: Notes should be nil
        XCTAssertNil(log.notes)
    }

    func testNotesUpdate_CanUpdateExistingNotes() {
        // Given: A log with existing notes
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000,
            notes: "Original notes"
        )

        // When: Updating notes
        log.notes = "Updated notes with more detail"

        // Then: Notes should be updated
        XCTAssertEqual(log.notes, "Updated notes with more detail")
    }

    // MARK: - Notes Change Detection Tests

    func testNotesChangeDetection_DetectsChange() {
        // Given: Original and new notes
        let originalNotes = "Original"
        let newNotes = "Updated"

        // When: Comparing
        let notesChanged = newNotes != originalNotes

        // Then: Should detect change
        XCTAssertTrue(notesChanged)
    }

    func testNotesChangeDetection_DetectsNoChange() {
        // Given: Same notes
        let originalNotes = "Same notes"
        let newNotes = "Same notes"

        // When: Comparing
        let notesChanged = newNotes != originalNotes

        // Then: Should not detect change
        XCTAssertFalse(notesChanged)
    }

    func testNotesChangeDetection_NilToEmpty() {
        // Given: Original nil notes, new empty string
        let originalNotes: String? = nil
        let newNotes = ""

        // When: Comparing (both represent "no notes")
        let notesChanged = (newNotes.isEmpty ? nil : newNotes) != nil && (originalNotes ?? "") != newNotes

        // Then: Should not detect change (nil and empty are equivalent)
        XCTAssertFalse(notesChanged)
    }

    // MARK: - Attachment Tests

    func testServiceLog_AttachmentsDefaultEmpty() {
        // Given: A new service log
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000
        )

        // Then: Attachments should be empty
        XCTAssertTrue((log.attachments ?? []).isEmpty)
    }

    func testServiceLog_SupportsMultipleAttachments() {
        // Given: A log and multiple attachments
        let log = ServiceLog(
            performedDate: Date.now,
            mileageAtService: 32000
        )

        let attachment1 = ServiceAttachment(
            serviceLog: log,
            data: Data(),
            fileName: "receipt1.jpg",
            mimeType: "image/jpeg"
        )

        let attachment2 = ServiceAttachment(
            serviceLog: log,
            data: Data(),
            fileName: "receipt2.pdf",
            mimeType: "application/pdf"
        )

        // Then: Attachments should have different IDs
        XCTAssertNotEqual(attachment1.id, attachment2.id)
        XCTAssertEqual(attachment1.serviceLog?.id, log.id)
        XCTAssertEqual(attachment2.serviceLog?.id, log.id)
    }

    // MARK: - Analytics Event Tests

    func testServiceLogEditedEvent_HasCorrectName() {
        // Given: A service log edited event
        let event = AnalyticsEvent.serviceLogEdited(notesChanged: true, attachmentsAdded: 2)

        // Then: Should have correct name
        XCTAssertEqual(event.name, "service_log_edited")
    }

    func testServiceLogEditedEvent_HasCorrectProperties() {
        // Given: A service log edited event
        let event = AnalyticsEvent.serviceLogEdited(notesChanged: true, attachmentsAdded: 3)

        // Then: Should have correct properties
        let props = event.properties
        XCTAssertEqual(props["notes_changed"] as? Bool, true)
        XCTAssertEqual(props["attachments_added"] as? Int, 3)
    }

    func testServiceLogEditedEvent_NoChanges() {
        // Given: An edit with no actual changes
        let event = AnalyticsEvent.serviceLogEdited(notesChanged: false, attachmentsAdded: 0)

        // Then: Properties should reflect no changes
        let props = event.properties
        XCTAssertEqual(props["notes_changed"] as? Bool, false)
        XCTAssertEqual(props["attachments_added"] as? Int, 0)
    }

    // MARK: - Screen Name Tests

    func testEditServiceLogScreenName_Exists() {
        // Given: The edit service log screen name
        let screenName = AnalyticsEvent.ScreenName.editServiceLog

        // Then: Should have correct raw value
        XCTAssertEqual(screenName.rawValue, "edit_service_log")
    }

    // MARK: - Full-Field Edit Symmetry
    //
    // The edit form now mirrors the record form: date, mileage, cost,
    // category, and notes are all editable. These tests cover the in-place
    // mutation of those fields on the existing ServiceLog so a fix doesn't
    // accidentally create a new entry.

    func testEditableFields_DateMutatesInPlace() {
        let log = ServiceLog(performedDate: Date(timeIntervalSince1970: 1_700_000_000), mileageAtService: 32000)
        let newDate = Date(timeIntervalSince1970: 1_710_000_000)
        log.performedDate = newDate
        XCTAssertEqual(log.performedDate, newDate)
    }

    func testEditableFields_MileageMutatesInPlace() {
        let log = ServiceLog(performedDate: Date.now, mileageAtService: 30000)
        log.mileageAtService = 31250
        XCTAssertEqual(log.mileageAtService, 31250)
    }

    func testEditableFields_CostAndCategoryMutateTogether() {
        let log = ServiceLog(performedDate: Date.now, mileageAtService: 30000, cost: 45, costCategory: .maintenance)
        log.cost = 95
        log.costCategory = .repair
        XCTAssertEqual(log.cost, 95)
        XCTAssertEqual(log.costCategory, .repair)
    }

    func testEditableFields_ClearingCostClearsCategory() {
        // Mirrors the saveChanges() rule: if cost becomes nil, category is dropped.
        let log = ServiceLog(performedDate: Date.now, mileageAtService: 30000, cost: 45, costCategory: .maintenance)
        let newCost: Decimal? = nil
        log.cost = newCost
        log.costCategory = newCost != nil ? .maintenance : nil
        XCTAssertNil(log.cost)
        XCTAssertNil(log.costCategory)
    }

    // MARK: - History exclusion when editing
    //
    // When editing an existing log, the sanity warnings and last-cost hint
    // must exclude that log from the comparison set — otherwise editing your
    // own entry would compare against itself.

    @MainActor
    func testHistoryExclusion_MedianCostIgnoresEditedLog() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self,
            configurations: config
        )
        let context = container.mainContext
        let vehicle = Vehicle(name: "Daily", make: "T", model: "C", year: 2020, currentMileage: 30000)
        context.insert(vehicle)
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        context.insert(service)

        let edited = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 30000, cost: 99)
        let other1 = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 28000, cost: 40)
        let other2 = ServiceLog(service: service, vehicle: vehicle, performedDate: Date(), mileageAtService: 29000, cost: 50)
        context.insert(edited)
        context.insert(other1)
        context.insert(other2)

        let logs = [edited, other1, other2]
        let othersMedian = logs.filter { $0.id != edited.id }.medianCost(serviceName: "Oil Change", vehicle: vehicle)

        XCTAssertEqual(othersMedian, 45, "Median should exclude the log being edited")
    }
}
