//
//  ServiceFormDraft.swift
//  checkpoint
//
//  Snapshot of in-progress service form state, persisted so the form survives
//  dismissal or the app being killed (F10). Attachments are excluded — they
//  live on disk/CloudKit already and aren't safe to re-attach blindly.
//
//  ## Versioning
//
//  v3 (the unified log form) replaced the seven timing chips with four plus a
//  due kind, so a v2 `timing` of `inSixMonths` means nothing now. A payload
//  that predates the current shape must fail *gracefully* — never crash, and
//  never half-apply. Two guards: `version` is non-optional, so a v1 payload
//  fails `Decodable` outright, and the store rejects any payload whose version
//  it does not recognise (a v2 `timing` it cannot decode fails too).
//  `ServiceFormDraftStore.load` discards and clears on either.
//

import Foundation

struct ServiceFormDraft: Codable, Equatable {
    /// Bump whenever a field's meaning changes in a way that would silently
    /// misread an older payload.
    static let currentVersion = 3

    var version: Int
    var timing: ServiceTiming?
    var customDate: Date
    var dueKind: ServiceDueKind?
    var dueDate: Date?
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
