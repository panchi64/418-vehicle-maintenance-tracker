//
//  ReceiptFormViews.swift
//  checkpoint
//
//  The service form's receipt pieces, ported from tools/sketchpad
//  (ServiceForm, "READING A RECEIPT"):
//
//    ReceiptScanRow        the form's first row. Before a scan it is an offer
//                          shaped like the More details trigger (accent 15 +
//                          tertiary 13); while reading, the wait is visible;
//                          after, the one `.info` line saying what the system
//                          filled in, with Clear beside it.
//    FromReceiptHint       under each filled field while it still holds the
//                          receipt's value — the F6 shape (`OriginalValueHint`).
//                          A value the reader was unsure of is a `.caution`
//                          beside the field that fixes it.
//    ReceiptLineItemsList  More details: the printed lines, a breakdown of the
//                          total, and whether they add up to it.
//

import SwiftUI

struct ReceiptScanRow: View {
    let receipt: ReceiptPrefill?
    let isReading: Bool
    let onScan: () -> Void
    let onClear: () -> Void

    var body: some View {
        if isReading {
            HStack(spacing: Spacing.sm) {
                ProgressView()
                    .tint(Theme.textPrimary)
                Text(L10n.receiptReading)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else if receipt != nil {
            HStack(alignment: .top, spacing: Spacing.sm) {
                FormAdvisory.info(L10n.receiptFilled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(L10n.receiptClear, action: onClear)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
                    .buttonStyle(.plain)
                    .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
                    .accessibilityLabel(L10n.receiptClearA11y)
            }
        } else {
            Button(action: onScan) {
                HStack(spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.receiptScanTitle)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.accent)
                        Text(L10n.receiptScanSummary)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 54)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: Theme.borderWidth)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.receiptScanTitle)
            .accessibilityHint(L10n.receiptScanSummary)
        }
    }
}

/// Provenance under a field that still holds the receipt's value.
struct FromReceiptHint: View {
    let confidence: ServiceReceiptDraft.Confidence
    /// A specific reason to check, when the validator gave one.
    var caution: String?

    var body: some View {
        if let caution {
            FormAdvisory.caution(caution)
        } else if confidence == .low {
            FormAdvisory.caution(L10n.receiptCheckValue)
        } else {
            OriginalValueHint(text: L10n.receiptFromReceipt)
        }
    }
}

/// The receipt's printed lines, in More details. Only the total counts toward
/// costs (`ExpenseEvent`); these say what it was made of.
struct ReceiptLineItemsList: View {
    let draft: ServiceReceiptDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.receiptItemsTitle)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(draft.lineItems.enumerated()), id: \.offset) { _, item in
                    row(item)
                }
            }

            if let total = draft.total {
                if ReceiptDraftValidator.addsUp(draft.lineItemSum, to: total)
                    || ReceiptDraftValidator.addsUp(draft.lineItemSum + (draft.tax ?? 0), to: total) {
                    Text(L10n.receiptItemsAddUp)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    FormAdvisory.caution(L10n.receiptItemsDontAddUp(
                        sum: Formatters.currency.string(from: draft.lineItemSum as NSDecimalNumber) ?? "",
                        total: Formatters.currency.string(from: total as NSDecimalNumber) ?? ""
                    ))
                }
            }
        }
    }

    private func row(_ item: ReceiptLineItem) -> some View {
        let amount = Formatters.currency.string(from: item.signedAmount as NSDecimalNumber) ?? ""
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.label)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                Text(item.kind.displayName)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(amount)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, Spacing.xs)
        .frame(minHeight: TouchTarget.minimum)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.gridLine).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
