//
//  L10n+Receipt.swift
//  checkpoint
//
//  Strings for reading receipts: the service form's receipt row and field
//  notes, the line-item list, receipt-reading failures, and Visual
//  Intelligence's result titles. Keys are prefixed `receipt.` and `visual.`.
//

import Foundation

extension L10n {
    nonisolated private static func receipt(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    nonisolated private static func receipt(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: receipt(key), arguments: arguments)
    }

    // MARK: - Form

    static var receiptScanTitle: String { receipt("receipt.scan.title") }
    static var receiptScanSummary: String { receipt("receipt.scan.summary") }
    static var receiptReading: String { receipt("receipt.reading") }
    /// The `.info` line once a receipt filled the form.
    static var receiptFilled: String { receipt("receipt.filled") }
    static var receiptClear: String { receipt("receipt.clear") }
    static var receiptClearA11y: String { receipt("receipt.clear.a11y") }
    /// Under a field that still holds the receipt's value.
    static var receiptFromReceipt: String { receipt("receipt.fromReceipt") }
    static var receiptCheckValue: String { receipt("receipt.checkValue") }
    /// "Lower than the 45,210 mi on file — check the receipt."
    static func receiptOdometerBelow(_ reading: String) -> String {
        receipt("receipt.odometerBelow", reading)
    }
    static var receiptItemsTitle: String { receipt("receipt.items.title") }
    static var receiptItemsAddUp: String { receipt("receipt.items.addUp") }
    /// "The items add up to $80.00, not the $91.91 total. The total is what's saved."
    static func receiptItemsDontAddUp(sum: String, total: String) -> String {
        receipt("receipt.items.dontAddUp", sum, total)
    }
    /// More details' collapsed summary when a receipt brought line items.
    static func receiptDepthSummary(_ category: String) -> String {
        receipt("receipt.depthSummary", category)
    }
    static var formShop: String { receipt("form.shop") }
    static var formShopPlaceholder: String { receipt("form.shop.placeholder") }

    // MARK: - Failures

    nonisolated static var receiptTooBlurry: String { receipt("receipt.tooBlurry") }
    static var receiptNothingRead: String { receipt("receipt.nothingRead") }

    // MARK: - Visual Intelligence

    static var visualLogReceipt: String { receipt("visual.logReceipt") }
    /// "Update mileage to 45,210 miles"
    static func visualUpdateMileage(_ reading: String) -> String { receipt("visual.updateMileage", reading) }
    /// "Add vehicle 1HGCM82633A004352"
    static func visualAddVehicle(_ vin: String) -> String { receipt("visual.addVehicle", vin) }
    /// "Checkpoint · Daily Driver"
    static func visualOnVehicle(_ vehicle: String) -> String { receipt("visual.onVehicle", vehicle) }
    static var visualInCheckpoint: String { receipt("visual.inCheckpoint") }
}

extension VisitLineItemKind {
    @MainActor
    var displayName: String {
        switch self {
        case .parts: return NSLocalizedString("lineItem.parts", comment: "")
        case .labor: return NSLocalizedString("lineItem.labor", comment: "")
        case .supplies: return NSLocalizedString("lineItem.supplies", comment: "")
        case .fees: return NSLocalizedString("lineItem.fees", comment: "")
        case .tax: return NSLocalizedString("lineItem.tax", comment: "")
        case .tip: return NSLocalizedString("lineItem.tip", comment: "")
        case .discount: return NSLocalizedString("lineItem.discount", comment: "")
        case .other: return NSLocalizedString("lineItem.other", comment: "")
        }
    }
}
