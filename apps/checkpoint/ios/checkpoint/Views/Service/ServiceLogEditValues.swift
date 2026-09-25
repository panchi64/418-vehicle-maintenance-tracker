//
//  ServiceLogEditValues.swift
//  checkpoint
//
//  The editable content of a service log, normalized the way the save path
//  writes it — so "changed" means "Save would write something different", not
//  "the text in a field differs". `45.990` and `45.99` are the same cost; a
//  category without a cost is dropped at save, so it can't make a form dirty;
//  empty notes are stored as nil.
//
//  Edit Service Log enables Save only when the current values differ from the
//  values it loaded (or an attachment is pending).
//

import Foundation

struct ServiceLogEditValues: Equatable {
    let performedDate: Date
    let mileage: Int?
    let cost: Decimal?
    let costCategory: CostCategory?
    let notes: String?

    init(
        performedDate: Date,
        mileage: Int?,
        costText: String,
        costCategory: CostCategory,
        notes: String
    ) {
        let cost = Decimal(string: costText)
        self.performedDate = performedDate
        self.mileage = mileage
        self.cost = cost
        // Mirrors `ServiceLog.applyEditedCost`: no cost, no category.
        self.costCategory = cost != nil ? costCategory : nil
        self.notes = notes.isEmpty ? nil : notes
    }
}
