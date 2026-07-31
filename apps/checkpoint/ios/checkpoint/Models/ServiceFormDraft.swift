//
//  ServiceFormDraft.swift
//  checkpoint
//
//  Snapshot of in-progress Add Service form state, persisted so the form
//  survives dismissal or the app being killed (F10). Attachments are excluded —
//  they live on disk/CloudKit already and aren't safe to re-attach blindly.
//
//  ## Versioning
//
//  The unified service form changed this shape: `mode` became `timing`, the two
//  per-mode notes buffers merged into one, and `performedDate` / `dueDate` /
//  `hasCustomDate` collapsed into a single `customDate`. A pre-refactor draft
//  therefore cannot be read as this type.
//
//  That must fail *gracefully* — never crash, and never half-apply. Two guards:
//  `version` is non-optional, so a v1 payload fails `Decodable` outright, and
//  the store additionally rejects any payload whose version it does not
//  recognise. `ServiceFormDraftStore.load` discards and clears on either.
//

import Foundation

struct ServiceFormDraft: Codable, Equatable {
    /// Bump whenever a field's meaning changes in a way that would silently
    /// misread an older payload.
    static let currentVersion = 2

    var version: Int
    var timing: ServiceTiming?
    var customDate: Date
    var serviceName: String
    var presetName: String?
    var costText: String
    var costCategoryRaw: String?
    var mileageText: String
    var notes: String
    var dueMileage: Int?
    var intervalMonths: Int?
    var intervalMiles: Int?
    var isRecurring: Bool
    var savedAt: Date
}
