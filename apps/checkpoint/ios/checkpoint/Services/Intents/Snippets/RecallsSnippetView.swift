//
//  RecallsSnippetView.swift
//  checkpoint
//
//  The card under "any recalls on my car?". A Readout whose one primary is
//  the count, the only line in the title face; then each recalled component,
//  with PARK IT (the recall card's own tag, word plus weight — never colour
//  alone) where NHTSA says not to drive, and PLANNED once it is on the
//  schedule. No recalls is one quiet line, not a card of absence.
//

import SwiftUI

struct RecallsSnippetView: View {
    struct Row: Identifiable {
        let id: String
        let component: String
        let parkIt: Bool
        let isPlanned: Bool
    }

    let vehicleName: String
    let rows: [Row]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(L10n.siriSnippetRecallCount(rows.count))
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text(vehicleName)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            if !rows.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(rows) { row in
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                            Text(row.component)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if row.parkIt {
                                tag(L10n.recallCardParkIt, color: Theme.statusOverdue)
                            }
                            if row.isPlanned {
                                tag(L10n.siriSnippetPlanned, color: Theme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.brutalistLabelBold)
            .tracking(1.5)
            .foregroundStyle(color)
    }
}
