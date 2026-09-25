//
//  L10n+Documents.swift
//  checkpoint
//
//  Strings added for the documents library's delete-with-Undo. Keys are
//  prefixed `documents.`; the older documents accessors stay in `L10n.swift`.
//

import Foundation

extension L10n {
    private static func documents(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static var documentsToastDeleted: String { documents("documents.toast.deleted") }
    static func documentsToastDeletedCount(_ count: Int) -> String {
        String(format: documents("documents.toast.deletedCount"), count)
    }
    static var documentsEditNotes: String { documents("documents.editNotes") }
    static var documentsFileNameLabel: String { documents("documents.fileNameLabel") }
    static var documentsFileNamePlaceholder: String { documents("documents.fileNamePlaceholder") }
}
