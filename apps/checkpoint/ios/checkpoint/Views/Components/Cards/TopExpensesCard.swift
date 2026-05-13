import SwiftUI

struct TopExpensesCard: View {
    let events: [ExpenseEvent]
    let onSelectLog: (ServiceLog) -> Void
    let onSelectVisit: (ServiceVisit) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.costsTopTitle)

            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    rowView(for: event)

                    if index < events.count - 1 {
                        ListDivider(leadingPadding: 28)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    @ViewBuilder
    private func rowView(for event: ExpenseEvent) -> some View {
        switch event {
        case .standalone(let log):
            ExpenseRow(log: log) { onSelectLog(log) }
        case .visit(let visit):
            VisitExpenseRow(visit: visit) { onSelectVisit(visit) }
        }
    }
}
