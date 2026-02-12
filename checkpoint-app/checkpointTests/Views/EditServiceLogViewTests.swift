//
//  EditServiceLogViewTests.swift
//  checkpointTests
//
//  Tests for EditServiceLogView — edit notes and add attachments to a service log
//

import XCTest
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
}
