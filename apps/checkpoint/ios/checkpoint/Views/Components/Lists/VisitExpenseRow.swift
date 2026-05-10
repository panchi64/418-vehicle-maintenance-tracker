//
//  VisitExpenseRow.swift
//  checkpoint
//
//  Single-row representation of a Service Visit inside expense lists.
//  Mirrors `ExpenseRow` so the two render side-by-side without visual
//  drift, but the row collapses N child services into one summary line —
//  the whole point of fixing the divide-by-N bug.
//

import SwiftUI

struct VisitExpenseRow: View {
    let visit: ServiceVisit
    let onTap: (() -> Void)?

    init(visit: ServiceVisit, onTap: (() -> Void)? = nil) {
        self.visit = visit
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            content
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var content: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.rectangle.stack")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(visit.costCategory?.color ?? Theme.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(serviceListLabel)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(formatDate(visit.performedDate))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)

                    Text("//")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)

                    Text("SERVICE VISIT")
                        .font(.brutalistLabel)
                        .foregroundStyle(visit.costCategory?.color ?? Theme.accent)
                        .tracking(0.5)
                }
            }

            Spacer()

            if let formattedTotal = visit.formattedTotalCost {
                Text(formattedTotal)
                    .font(.brutalistHeading)
                    .foregroundStyle(visit.costCategory?.color ?? Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Service Visit on \(formatDate(visit.performedDate)), \(visit.serviceCount) services")
        .accessibilityValue(visit.formattedTotalCost ?? "No total recorded")
        .accessibilityHint(onTap != nil ? "Double tap to view the visit" : "")
    }

    private var serviceListLabel: String {
        let count = visit.serviceCount
        switch count {
        case 0: return "Service Visit"
        case 1: return (visit.logs ?? []).first?.service?.name ?? "Service Visit"
        default: return "Service Visit · \(count) services"
        }
    }

    private func formatDate(_ date: Date) -> String {
        Formatters.mediumDate.string(from: date)
    }
}
