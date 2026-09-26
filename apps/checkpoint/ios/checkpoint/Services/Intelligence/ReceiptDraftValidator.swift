//
//  ReceiptDraftValidator.swift
//  checkpoint
//
//  Code checks every draft passes, whichever reader wrote it. A model can be
//  fluent and wrong, so its answer is held to the same arithmetic as the
//  rules', and where the two readers agree the value is trusted more:
//
//    - the line items add up to the total (the total is still what's saved)
//    - the date is plausible: not in the future, not years back
//    - the odometer is at least the reading on file, and within reach of it
//
//  A failed check lowers the field's confidence and records an `Issue`, which
//  the form shows as a `.caution` beside the field. Impossible values are
//  dropped rather than prefilled.
//

import Foundation

nonisolated enum ReceiptDraftValidator {

    /// How far a receipt date may sit in the past.
    static let oldestPlausibleYears = 10
    /// More than this beyond the reading on file is a misread, not driving.
    static let largestPlausibleJump = 150_000
    /// Line items within this of the total count as adding up (rounding on
    /// printed tax lines).
    static let reconciliationTolerance: Decimal = 0.05

    static func validate(_ draft: ServiceReceiptDraft, context: ReceiptContext) -> ServiceReceiptDraft {
        var draft = draft
        draft.issues = []

        // Date
        if let date = draft.date, !isPlausible(date, context: context) {
            draft.date = nil
            draft.issues.append(.implausibleDate)
        }

        // Odometer
        if let odometer = draft.odometer {
            let ceiling = (context.lastOdometer ?? 0) + largestPlausibleJump
            if odometer < 10 || odometer > ceiling {
                draft.odometer = nil
                draft.issues.append(.implausibleOdometer)
            } else if let last = context.lastOdometer, odometer < last {
                draft.confidence.odometer = .low
                draft.issues.append(.odometerBelowLastReading(lastReading: last))
            }
        }

        // Tax can't exceed the total it is part of.
        if let tax = draft.tax, let total = draft.total, tax >= total {
            draft.tax = nil
        }

        // Total against its breakdown.
        if !draft.lineItems.isEmpty {
            let sum = draft.lineItemSum
            if let total = draft.total {
                if addsUp(sum, to: total) || addsUp(sum + (draft.tax ?? 0), to: total) {
                    draft.confidence.total = .high
                } else {
                    draft.confidence.total = min(draft.confidence.total, .medium)
                    draft.issues.append(.lineItemsDontAddUp(sum: sum, total: total))
                }
            } else if sum > 0 {
                // No printed total: the items are all there is, and a guess.
                draft.total = sum
                draft.confidence.total = .low
            }
        }
        return draft
    }

    static func addsUp(_ sum: Decimal, to total: Decimal) -> Bool {
        let difference = sum - total
        return (difference < 0 ? -difference : difference) <= reconciliationTolerance
    }

    static func isPlausible(_ date: Date, context: ReceiptContext) -> Bool {
        let calendar = context.calendar
        guard let latest = calendar.date(byAdding: .day, value: 1, to: context.now),
              let earliest = calendar.date(byAdding: .year, value: -oldestPlausibleYears, to: context.now)
        else { return false }
        return date >= earliest && date <= latest
    }

    // MARK: - Two readers

    /// The model's draft, scored against the rules' reading of the same text.
    /// Agreement raises a field to high confidence; a value only the model
    /// found stays medium; where the model found nothing, the rules' value
    /// fills in with the rules' own confidence. Validate afterwards.
    static func merge(model: ServiceReceiptDraft, rules: ServiceReceiptDraft) -> ServiceReceiptDraft {
        var merged = model
        merged.source = .onDeviceModel

        func combine<Value: Equatable>(
            _ modelValue: Value?, _ rulesValue: Value?, rulesConfidence: ServiceReceiptDraft.Confidence
        ) -> (Value?, ServiceReceiptDraft.Confidence) {
            switch (modelValue, rulesValue) {
            case let (m?, r?) where m == r: return (m, .high)
            case let (m?, _): return (m, .medium)
            case let (nil, r?): return (r, rulesConfidence)
            case (nil, nil): return (nil, .medium)
            }
        }

        (merged.shopName, merged.confidence.shop) = combine(
            model.shopName, rules.shopName, rulesConfidence: rules.confidence.shop
        )
        (merged.total, merged.confidence.total) = combine(
            model.total, rules.total, rulesConfidence: rules.confidence.total
        )
        (merged.odometer, merged.confidence.odometer) = combine(
            model.odometer, rules.odometer, rulesConfidence: rules.confidence.odometer
        )
        let sameDay = model.date.flatMap { m in rules.date.map { Calendar.current.isDate(m, inSameDayAs: $0) } } ?? false
        if sameDay {
            merged.confidence.date = .high
        } else if model.date == nil {
            merged.date = rules.date
            merged.confidence.date = rules.confidence.date
        } else {
            merged.confidence.date = .medium
        }
        if merged.tax == nil { merged.tax = rules.tax }
        if merged.lineItems.isEmpty { merged.lineItems = rules.lineItems }

        let ruleServices = Set(rules.serviceNames.map { $0.lowercased() })
        if merged.serviceNames.isEmpty {
            merged.serviceNames = rules.serviceNames
            merged.confidence.services = rules.confidence.services
        } else {
            merged.confidence.services = merged.serviceNames.allSatisfy { ruleServices.contains($0.lowercased()) }
                ? .high : .medium
        }
        return merged
    }
}
