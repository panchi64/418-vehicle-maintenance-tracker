//
//  L10n+Notes.swift
//  checkpoint
//
//  On-screen strings for vehicle notes: the Notes list, its row in the specs
//  panel, and the note sheet. `notes.` / `noteForm.` keys.
//

import Foundation

extension L10n {
    private static func notes(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - List

    static var notesTitle: String { notes("notes.title") }
    static var notesRowQuickSpecs: String { notes("notes.rowQuickSpecs") }
    static var notesEmptyTitle: String { notes("notes.empty.title") }
    static var notesEmptyMessage: String { notes("notes.empty.message") }
    static var notesAdd: String { notes("notes.add") }
    static var notesPinned: String { notes("notes.pinned") }
    static var notesAll: String { notes("notes.all") }
    static var notesSearchPlaceholder: String { notes("notes.searchPlaceholder") }
    static var notesDeleteConfirmTitle: String { notes("notes.delete.confirmTitle") }
    static var notesDeleteConfirmMessage: String { notes("notes.delete.confirmMessage") }
    static var notesPin: String { notes("notes.pin") }
    static var notesUnpin: String { notes("notes.unpin") }
    static var notesPinnedA11y: String { notes("notes.pinnedA11y") }
    static var notesUntitled: String { notes("notes.untitled") }
    /// "Sep 12, 2026 · 2 attachments" — date, attachment count.
    static func notesMetaWithAttachments(_ date: String, _ attachments: String) -> String {
        String(format: notes("notes.metaWithAttachments"), date, attachments)
    }

    // MARK: - Sheet

    static var noteFormTitleNew: String { notes("noteForm.titleNew") }
    static var noteFormTitleEdit: String { notes("noteForm.titleEdit") }
    static var noteFormNote: String { notes("noteForm.note") }
    static var noteFormTitleField: String { notes("noteForm.title") }
    static var noteFormTitlePlaceholder: String { notes("noteForm.title.placeholder") }
    static var noteFormNeedsText: String { notes("noteForm.needsText") }
    static var noteFormText: String { notes("noteForm.text") }
    static var noteFormTextPlaceholder: String { notes("noteForm.text.placeholder") }
    static var noteFormRemoveAttachment: String { notes("noteForm.removeAttachment") }
    static var noteFormAttachmentsHint: String { notes("noteForm.attachmentsHint") }
    static var noteFormPinned: String { notes("noteForm.pinned") }
    static var noteFormPinnedA11y: String { notes("noteForm.pinnedA11y") }
    static var noteFormDelete: String { notes("noteForm.delete") }
}
