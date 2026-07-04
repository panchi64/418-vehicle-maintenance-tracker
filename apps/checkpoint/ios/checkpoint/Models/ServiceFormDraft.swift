//
//  ServiceFormDraft.swift
//  checkpoint
//
//  Snapshot of in-progress Add Service form state, persisted so the form
//  survives dismissal or the app being killed (R9). Attachments are excluded —
//  they live on disk/CloudKit already and aren't safe to re-attach blindly.
//

import Foundation

struct ServiceFormDraft: Codable, Equatable {
    var mode: String
    var serviceName: String
    var presetName: String?
    var performedDate: Date
    var costText: String
    var costCategoryRaw: String?
    var mileageText: String
    var recordNotes: String
    var remindNotes: String
    var dueDate: Date?
    var hasCustomDate: Bool
    var dueMileage: Int?
    var intervalMonths: Int?
    var intervalMiles: Int?
    var isRecurring: Bool
    var savedAt: Date
}
