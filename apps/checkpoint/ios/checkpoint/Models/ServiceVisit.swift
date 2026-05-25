//
//  ServiceVisit.swift
//  checkpoint
//
//  SwiftData model for a Service Visit — one shop visit, one honest total,
//  N child ServiceLogs. Replaces the old "divide cluster total by service count"
//  bug with a first-class persisted entity.
//

import Foundation
import SwiftData

@Model
final class ServiceVisit: Identifiable {
    var id: UUID = UUID()
    var vehicle: Vehicle?

    var performedDate: Date = Date.now
    var mileageAtVisit: Int = 0

    /// User-entered total. Source of truth for visit-level cost.
    /// May be nil when a visit is logged without a cost.
    var totalCost: Decimal?

    /// Primary category for the visit. Per-service categories on child logs
    /// are only meaningful when `isItemized == true`.
    var costCategory: CostCategory?

    /// True when the user opted in to itemize per-service costs.
    /// When false, child logs' `cost` is nil and `totalCost` is the truth.
    var isItemized: Bool = false

    var shopName: String?
    var notes: String?
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \ServiceLog.visit)
    var logs: [ServiceLog]? = []

    @Relationship(deleteRule: .cascade, inverse: \VisitLineItem.visit)
    var lineItems: [VisitLineItem]? = []

    init(
        vehicle: Vehicle? = nil,
        performedDate: Date = .now,
        mileageAtVisit: Int = 0,
        totalCost: Decimal? = nil,
        costCategory: CostCategory? = nil,
        isItemized: Bool = false,
        shopName: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now
    ) {
        self.vehicle = vehicle
        self.performedDate = performedDate
        self.mileageAtVisit = mileageAtVisit
        self.totalCost = totalCost
        self.costCategory = costCategory
        self.isItemized = isItemized
        self.shopName = shopName
        self.notes = notes
        self.createdAt = createdAt
    }
}

extension ServiceVisit {
    var formattedTotalCost: String? {
        guard let total = totalCost else { return nil }
        return Formatters.currency.string(from: total as NSDecimalNumber)
    }

    /// Number of child service logs in this visit.
    var serviceCount: Int { (logs ?? []).count }
}
