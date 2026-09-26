//
//  SpendingSnippetView.swift
//  checkpoint
//
//  The small card under "how much have I spent on the Civic this year?".
//  A Readout with one primary element — the total, the only number set in
//  the title face — then the period, then the period's spend per category in
//  the Costs tab's fixed category order. Categories with nothing spent are
//  left out rather than listed as zero.
//

import SwiftUI

struct SpendingSnippetView: View {
    let total: String
    /// "Daily Driver · Year to Date".
    let caption: String
    /// Category name and amount, in display order. Empty when the answer is
    /// already narrowed to one category.
    let breakdown: [(label: String, amount: String)]
    let expenseCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(total)
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text(caption)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            if !breakdown.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(breakdown, id: \.label) { row in
                        BrutalistDataRow(label: row.label, value: row.amount)
                    }
                }
            }
            BrutalistDataRow(label: L10n.siriSnippetExpenses, value: "\(expenseCount)")
        }
        .padding(Spacing.md)
    }
}
