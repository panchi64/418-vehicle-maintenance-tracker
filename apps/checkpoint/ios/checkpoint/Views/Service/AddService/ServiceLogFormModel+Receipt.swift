//
//  ServiceLogFormModel+Receipt.swift
//  checkpoint
//
//  A read receipt (`ServiceReceiptDraft`) applied to the form. Resolved in
//  tools/sketchpad (ServiceForm, "READING A RECEIPT"):
//
//    - Values land IN their own fields — service, when, odometer, cost, and
//      a shop field that appears only for a receipt. No second copy of the
//      total anywhere (Decision rule 7).
//    - A field is SUGGESTED while it still holds exactly what the receipt
//      said; edit it and it is the user's. Derived, not tracked, so there is
//      no state to fall out of step.
//    - Clearing puts back what the form held before the scan.
//    - Save confirms: no separate "use these" step.
//

import Foundation

/// The receipt behind the form's suggestions, and the form as it was before.
struct ReceiptPrefill {
    let draft: ServiceReceiptDraft
    /// The form before the receipt, for Clear.
    let before: ServiceFormDraft
    let shopBefore: String

    /// What was written into each field, to tell suggestion from edit.
    let serviceName: String?
    let timing: ServiceTiming?
    let customDate: Date?
    let mileage: Int?
    let cost: String?
    let shopName: String?
}

extension ServiceLogFormModel {

    /// A field a receipt can fill.
    enum ReceiptField {
        case service, date, odometer, cost, shop
    }

    /// Fill the form from `draft`. A locked service (Mark Done) stays locked;
    /// the receipt's date picks the matching When chip.
    func apply(receipt draft: ServiceReceiptDraft, now: Date = .now) {
        let before = receipt?.before ?? toDraft()
        let shopBefore = receipt?.shopBefore ?? shopName

        var appliedName: String?
        if !mode.isServiceLocked, let name = draft.serviceNames.first {
            choose(name: name)
            appliedName = serviceName
        }

        var appliedTiming: ServiceTiming?
        var appliedDate: Date?
        if let date = draft.date {
            let timing = ServiceLogging.timing(for: date, now: now)
            self.timing = timing
            appliedTiming = timing
            if timing == .earlier {
                customDate = date
                appliedDate = date
            }
        }

        if let odometer = draft.odometer { mileageAtService = odometer }
        let appliedCost = draft.total.map(Self.costText)
        if let appliedCost { cost = appliedCost }
        if let shop = draft.shopName { shopName = shop }

        receipt = ReceiptPrefill(
            draft: draft,
            before: before,
            shopBefore: shopBefore,
            serviceName: appliedName,
            timing: appliedTiming,
            customDate: appliedDate,
            mileage: draft.odometer,
            cost: appliedCost,
            shopName: draft.shopName
        )
    }

    /// Put the form back as it was before the receipt.
    func clearReceipt() {
        guard let receipt else { return }
        apply(receipt.before)
        shopName = receipt.shopBefore
        self.receipt = nil
    }

    /// Whether `field` still holds the receipt's value.
    func isSuggested(_ field: ReceiptField) -> Bool {
        guard let receipt else { return false }
        switch field {
        case .service:
            guard let name = receipt.serviceName else { return false }
            return serviceName == name
        case .date:
            guard let applied = receipt.timing, timing == applied else { return false }
            guard applied == .earlier, let date = receipt.customDate else { return true }
            return Calendar.current.isDate(customDate, inSameDayAs: date)
        case .odometer:
            return receipt.mileage != nil && mileageAtService == receipt.mileage
        case .cost:
            return receipt.cost != nil && cost == receipt.cost
        case .shop:
            return receipt.shopName != nil && shopName == receipt.shopName
        }
    }

    /// How sure the reader was of `field`'s value.
    func receiptConfidence(_ field: ReceiptField) -> ServiceReceiptDraft.Confidence {
        guard let confidence = receipt?.draft.confidence else { return .medium }
        switch field {
        case .service: return confidence.services
        case .date: return confidence.date
        case .odometer: return confidence.odometer
        case .cost: return confidence.total
        case .shop: return confidence.shop
        }
    }

    /// Whether the form shows the shop field: only for a receipt that named
    /// one, while logging.
    var showsShopField: Bool {
        isLogging && receipt?.draft.shopName != nil
    }

    /// The shop and line items a save puts on a visit, or nil when the entry
    /// has neither (it stays a standalone log, as always).
    var receiptVisitDetails: (shopName: String?, lineItems: [ReceiptLineItem])? {
        guard let receipt, isLogging, !mode.isEdit else { return nil }
        let shop = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = receipt.draft.lineItems
        guard !shop.isEmpty || !items.isEmpty else { return nil }
        return (shop.isEmpty ? nil : shop, items)
    }

    /// A total as the cost field holds it: two decimals, "." separator
    /// (`LoggedServiceWriter` reads it with `Decimal(string:)`).
    static func costText(_ amount: Decimal) -> String {
        let rounded = NSDecimalNumber(decimal: amount).rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .plain, scale: 2, raiseOnExactness: false, raiseOnOverflow: false,
            raiseOnUnderflow: false, raiseOnDivideByZero: false
        ))
        return String(format: "%.2f", rounded.doubleValue)
    }
}
