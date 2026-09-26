//
//  VisitLineItem.swift
//  checkpoint
//
//  Optional non-service charges attached to a ServiceVisit (parts, labor,
//  tax, tip, discount, etc.). Declared in Phase A so the schema does not
//  need to migrate again when Phase B turns on the itemize/line-item UI.
//

import Foundation
import SwiftData

@Model
final class VisitLineItem: Identifiable {
    var id: UUID = UUID()
    var visit: ServiceVisit?

    var label: String = ""
    var kind: VisitLineItemKind = VisitLineItemKind.other
    var amount: Decimal = 0
    var createdAt: Date = Date.now

    init(
        visit: ServiceVisit? = nil,
        label: String = "",
        kind: VisitLineItemKind = .other,
        amount: Decimal = 0,
        createdAt: Date = .now
    ) {
        self.visit = visit
        self.label = label
        self.kind = kind
        self.amount = amount
        self.createdAt = createdAt
    }
}

/// `nonisolated` so receipt reading (`Services/Intelligence`) can carry it in
/// its Sendable drafts; only `displayName` reads the main-actor `L10n`.
nonisolated enum VisitLineItemKind: String, Codable, CaseIterable, Sendable {
    case parts
    case labor
    case supplies
    case fees
    case tax
    case tip
    case discount
    case other
}
