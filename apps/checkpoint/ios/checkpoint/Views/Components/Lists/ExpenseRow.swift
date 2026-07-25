//
//  ExpenseRow.swift
//  checkpoint
//
//  Maps a `ServiceLog` onto `ServiceEventRow`. This type owns only the
//  model-to-row translation; layout and hierarchy live in the shared shell so
//  expense rows, history rows, and activity rows cannot drift apart again.
//

import SwiftUI

struct ExpenseRow: View {
    let log: ServiceLog
    let onTap: (() -> Void)?
    let isAnomalous: Bool
    let isHighlighted: Bool

    init(
        log: ServiceLog,
        isAnomalous: Bool = false,
        isHighlighted: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.log = log
        self.onTap = onTap
        self.isAnomalous = isAnomalous
        self.isHighlighted = isHighlighted
    }

    private var title: String {
        log.service?.name ?? L10n.rowServiceFallback
    }

    private var formattedDate: String {
        Formatters.mediumDate.string(from: log.performedDate)
    }

    private var metadata: [ServiceEventRow.Metadatum] {
        var items: [ServiceEventRow.Metadatum] = [.detail(formattedDate)]

        if let category = log.costCategory {
            items.append(.tag(category.displayName.uppercased(), color: category.color))
        }
        if isAnomalous {
            items.append(.tag(L10n.costsRowOutlier, color: Theme.statusOverdue))
        }
        return items
    }

    var body: some View {
        ServiceEventRow(
            indicator: .category(log.costCategory),
            title: title,
            metadata: metadata,
            // Expense rows show cents via Formatters.currency (e.g. "$125.50")
            // while summary/stat cards use currencyWhole (e.g. "$126").
            amount: log.formattedCost.map {
                .init(text: $0, color: log.costCategory?.color ?? Theme.accent)
            },
            isHighlighted: isHighlighted,
            accessibilityValueText: log.formattedCost ?? L10n.rowNoCostRecorded,
            accessibilityLabelText: "\(title), \(formattedDate)"
                + (isAnomalous ? L10n.rowOutlierAccessibility : ""),
            onTap: onTap
        )
    }
}

#Preview {
    let log1 = ServiceLog(
        performedDate: .now,
        mileageAtService: 45000,
        cost: 125.50,
        notes: "Oil and filter changed"
    )
    log1.costCategory = .maintenance

    let log2 = ServiceLog(
        performedDate: Calendar.current.date(byAdding: .day, value: -10, to: .now)!,
        mileageAtService: 44500,
        cost: 450.00
    )
    log2.costCategory = .repair

    let log3 = ServiceLog(
        performedDate: Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
        mileageAtService: 43000,
        cost: 89.99
    )

    return ZStack {
        AtmosphericBackground()

        VStack(spacing: 0) {
            ExpenseRow(log: log1) { print("Tapped") }
            ListDivider(leadingPadding: 28)
            ExpenseRow(log: log2, isAnomalous: true) { print("Tapped") }
            ListDivider(leadingPadding: 28)
            ExpenseRow(log: log3) { print("Tapped") }
        }
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
