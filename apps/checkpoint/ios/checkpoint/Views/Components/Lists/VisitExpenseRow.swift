//
//  VisitExpenseRow.swift
//  checkpoint
//
//  Maps a `ServiceVisit` onto `ServiceEventRow`. The row collapses N child
//  services into one summary line — the whole point of fixing the divide-by-N
//  bug, where a single entered total was split across children and stored as a
//  fabricated per-service cost.
//
//  Shares `ServiceEventRow` with `ExpenseRow` so the two render side-by-side in
//  the same list without drifting apart. Previously they were separate
//  implementations kept in sync by hand.
//

import SwiftUI

struct VisitExpenseRow: View {
    let visit: ServiceVisit
    let onTap: (() -> Void)?
    let isAnomalous: Bool

    init(
        visit: ServiceVisit,
        isAnomalous: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.visit = visit
        self.onTap = onTap
        self.isAnomalous = isAnomalous
    }

    private var tint: Color {
        visit.costCategory?.color ?? Theme.accent
    }

    private var formattedDate: String {
        Formatters.mediumDate.string(from: visit.performedDate)
    }

    /// A single-service visit reads as that service; multiple reads as a count.
    private var title: String {
        switch visit.serviceCount {
        case 0:
            return L10n.rowVisitTitle
        case 1:
            return (visit.logs ?? []).first?.service?.name ?? L10n.rowVisitTitle
        default:
            return L10n.rowVisitTitleCount(visit.serviceCount)
        }
    }

    private var metadata: [ServiceEventRow.Metadatum] {
        var items: [ServiceEventRow.Metadatum] = [
            .detail(formattedDate),
            .tag(L10n.rowVisitTag, color: tint)
        ]
        if isAnomalous {
            items.append(.tag(L10n.costsRowOutlier, color: Theme.statusOverdue))
        }
        return items
    }

    var body: some View {
        ServiceEventRow(
            indicator: .bundledVisit(tint),
            title: title,
            metadata: metadata,
            amount: visit.formattedTotalCost.map { .init(text: $0, color: tint) },
            accessibilityValueText: visit.formattedTotalCost ?? L10n.rowNoTotalRecorded,
            accessibilityLabelText: L10n.rowVisitAccessibility(formattedDate, visit.serviceCount),
            onTap: onTap
        )
    }
}
