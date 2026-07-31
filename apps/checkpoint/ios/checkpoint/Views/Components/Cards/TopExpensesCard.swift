import SwiftUI

struct TopExpensesCard: View {
    let events: [ExpenseEvent]
    let onSelectLog: (ServiceLog) -> Void
    let onSelectVisit: (ServiceVisit) -> Void

    // Unboxed, matching every other divider-separated list. This one is a list
    // despite the "Card" name — the enclosure was the only thing making it read
    // as a card, and it competed with the headline and stat cards above it,
    // which genuinely are.
    var body: some View {
        ReadoutSection(title: L10n.costsTopTitle) {
            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    rowView(for: event)

                    if index < events.count - 1 {
                        ListDivider()
                    }
                }
            }
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
