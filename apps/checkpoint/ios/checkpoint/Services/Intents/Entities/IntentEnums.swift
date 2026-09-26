//
//  IntentEnums.swift
//  checkpoint
//
//  The app's own enums, exposed to Siri and Shortcuts as `AppEnum`s. They
//  conform in place rather than being mirrored, so an intent parameter and
//  the model can never disagree about the cases. Raw values are the models'
//  storage values, which App Intents also persists in saved shortcuts — never
//  rename one.
//
//  `nonisolated` extensions: the enums are nonisolated, and App Intents reads
//  these requirements off the main actor.
//

import AppIntents

nonisolated extension CostPeriod: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Period" }

    static var caseDisplayRepresentations: [CostPeriod: DisplayRepresentation] {
        [
            .last30Days: "Last 30 Days",
            .yearToDate: "Year to Date",
            .last12Months: "Last 12 Months",
            .allTime: "All Time",
        ]
    }
}

nonisolated extension CostCategory: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Cost Category" }

    static var caseDisplayRepresentations: [CostCategory: DisplayRepresentation] {
        [
            .maintenance: DisplayRepresentation(title: "Maintenance", image: .init(systemName: "wrench.and.screwdriver")),
            .repair: DisplayRepresentation(title: "Repair", image: .init(systemName: "exclamationmark.triangle")),
            .upgrade: DisplayRepresentation(title: "Upgrade", image: .init(systemName: "arrow.up.circle")),
        ]
    }
}

nonisolated extension DocumentType: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Document Type" }

    static var caseDisplayRepresentations: [DocumentType: DisplayRepresentation] {
        [
            .registration: DisplayRepresentation(title: "Registration", image: .init(systemName: "doc.text.fill")),
            .insurance: DisplayRepresentation(title: "Insurance", image: .init(systemName: "shield.fill")),
            .title: DisplayRepresentation(title: "Title", image: .init(systemName: "doc.richtext.fill")),
            .inspection: DisplayRepresentation(title: "Inspection", image: .init(systemName: "checkmark.seal.fill")),
            .warranty: DisplayRepresentation(title: "Warranty", image: .init(systemName: "checkmark.shield.fill")),
            .manual: DisplayRepresentation(title: "Manual", image: .init(systemName: "book.fill")),
            .receipt: DisplayRepresentation(title: "Receipt", image: .init(systemName: "receipt.fill")),
            .other: DisplayRepresentation(title: "Other", image: .init(systemName: "doc.fill")),
        ]
    }
}

nonisolated extension ServiceStatus: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Service Status" }

    /// Same words as the in-app status tags (`ServiceStatus.label`).
    static var caseDisplayRepresentations: [ServiceStatus: DisplayRepresentation] {
        [
            .overdue: "Overdue",
            .dueSoon: "Due Soon",
            .good: "On Track",
            .neutral: "Not Scheduled",
        ]
    }
}
