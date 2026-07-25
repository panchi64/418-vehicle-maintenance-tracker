//
//  InsufficientDataNote.swift
//  checkpoint
//
//  One quiet line for "not enough data yet" (Readout rule 3).
//
//  Why this exists: the Costs tab rendered full-size bordered cards whose only
//  content was an absence — "3+ expenses to show spending pace", "Expenses in
//  2+ months to show trends". Two of them could appear at once, so a new
//  user's most data-hungry screen was substantially made of apologies, each
//  occupying as much space and visual weight as a real chart.
//
//  A missing chart is worth one line at the quietest level in the scale. It is
//  never worth a card, because a card claims the same importance as content.
//
//  This is deliberately not `EmptyStateView`: that type is for a screen with
//  nothing on it at all, and correctly gets an icon and a call to action. This
//  is for one absent element on a screen that otherwise has content.
//

import SwiftUI

struct InsufficientDataNote: View {
    /// What would make this appear, phrased as the condition rather than the
    /// failure: "3 or more expenses shows your spending pace" reads as a
    /// preview of something coming, not as a rebuke for having no data.
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(width: Theme.borderWidth, height: 12)
                .accessibilityHidden(true)

            Text(message)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()

        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("$1,847")
                .font(.brutalistTitle)
                .foregroundStyle(Theme.accent)

            InsufficientDataNote(message: "Three or more expenses shows your spending pace.")
            InsufficientDataNote(message: "Expenses in two or more months shows monthly trends.")
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
