//
//  ServiceReceiptDraft.swift
//  checkpoint
//
//  What reading a shop receipt produces: a DRAFT, never a record. Every
//  consumer (the service form, Log Receipt, Visual Intelligence) shows it
//  back to the user before anything is written, and each field carries how
//  sure the reader was, so a shaky value is flagged beside its field.
//
//  Money follows the app's one cost rule (`ExpenseEvent`): the total is the
//  cost. Line items are a breakdown of it — stored on the visit, never added
//  on top.
//

import Foundation

nonisolated struct ServiceReceiptDraft: Equatable, Sendable {

    /// How sure the reader is of one value. Ordered: `low < medium < high`.
    nonisolated enum Confidence: Int, Comparable, Sendable {
        /// Found, but it failed a check or came from a guess — show it, and
        /// ask the user to look.
        case low
        /// Found once, with nothing to corroborate it.
        case medium
        /// Labelled on the receipt ("TOTAL") or read by two paths that agree.
        case high

        static func < (lhs: Confidence, rhs: Confidence) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// Per-field confidence. A field that wasn't found has no confidence
    /// worth showing; its value is nil.
    nonisolated struct FieldConfidence: Equatable, Sendable {
        var shop: Confidence = .medium
        var date: Confidence = .medium
        var total: Confidence = .medium
        var odometer: Confidence = .medium
        var services: Confidence = .medium
    }

    /// Why a value was marked down. Surfaced as `.caution` advisories.
    nonisolated enum Issue: Equatable, Sendable {
        /// The items don't add up to the total. The total is still what's saved.
        case lineItemsDontAddUp(sum: Decimal, total: Decimal)
        /// A date in the future, or years back — dropped.
        case implausibleDate
        /// Lower than the reading already on file.
        case odometerBelowLastReading(lastReading: Int)
        /// Far beyond anything the vehicle could have driven — dropped.
        case implausibleOdometer
    }

    /// Which reader produced the draft.
    nonisolated enum Source: Equatable, Sendable {
        /// Apple's on-device model (guided generation over the transcript,
        /// plus the photo on iOS 27).
        case onDeviceModel
        /// The rule-based reader: iOS 26 without Apple Intelligence, or when
        /// the model fails.
        case rules
    }

    var shopName: String?
    var date: Date?
    var total: Decimal?
    var tax: Decimal?
    var odometer: Int?
    var lineItems: [ReceiptLineItem] = []
    /// Services on the receipt, already matched to the vehicle's own service
    /// names or the preset catalog, so a match completes a tracked service
    /// instead of duplicating it.
    var serviceNames: [String] = []
    var confidence = FieldConfidence()
    var issues: [Issue] = []
    var source: Source = .rules

    /// Nothing worth prefilling. A shop name alone doesn't count: any first
    /// line of text can look like one.
    var isEmpty: Bool {
        date == nil && total == nil && odometer == nil && serviceNames.isEmpty && lineItems.isEmpty
    }

    /// The line items' sum, discounts subtracting. What reconciliation
    /// compares with the total.
    var lineItemSum: Decimal {
        lineItems.reduce(Decimal.zero) { $0 + $1.signedAmount }
    }
}

/// One printed line: a breakdown entry of the total.
nonisolated struct ReceiptLineItem: Equatable, Sendable {
    var label: String
    var kind: VisitLineItemKind
    /// Always positive as printed; `signedAmount` applies a discount's sign.
    var amount: Decimal

    var signedAmount: Decimal { kind == .discount ? -amount : amount }
}

/// Everything the readers know about the vehicle the receipt is for.
nonisolated struct ReceiptContext: Sendable {
    /// The vehicle's service names and the preset catalog, most specific
    /// first. Receipt services are matched to these.
    var knownServiceNames: [String]
    /// The odometer on file, in stored miles.
    var lastOdometer: Int?
    var now: Date = .now
    var calendar: Calendar = .current

    static let empty = ReceiptContext(knownServiceNames: [], lastOdometer: nil)
}
