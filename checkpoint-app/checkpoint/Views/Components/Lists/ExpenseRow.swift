//
//  ExpenseRow.swift
//  checkpoint
//
//  Row component for displaying a service log expense item
//

import SwiftUI

struct ExpenseRow: View {
    let log: ServiceLog
    let onTap: (() -> Void)?

    init(log: ServiceLog, onTap: (() -> Void)? = nil) {
        self.log = log
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
            // Category icon or default
            if let category = log.costCategory {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(category.color)
                    .frame(width: 20)
            } else {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(log.service?.name ?? "Service")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(formatDate(log.performedDate))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)

                    if let category = log.costCategory {
                        Text("//")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)

                        Text(category.displayName.uppercased())
                            .font(.brutalistLabel)
                            .foregroundStyle(category.color)
                            .tracking(0.5)
                    }
                }
            }

            Spacer()

            // Expense rows show cents via Formatters.currency (e.g. "$125.50")
            // while summary/stat cards use Formatters.currencyWhole (e.g. "$126")
            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistHeading)
                    .foregroundStyle(log.costCategory?.color ?? Theme.accent)
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
        .accessibilityLabel("\(log.service?.name ?? "Service"), \(formatDate(log.performedDate))")
        .accessibilityValue(log.formattedCost ?? "No cost recorded")
        .accessibilityHint(onTap != nil ? "Double tap to view details" : "")
    }

    private func formatDate(_ date: Date) -> String {
        Formatters.mediumDate.string(from: date)
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
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)
                .padding(.leading, 28)
            ExpenseRow(log: log2) { print("Tapped") }
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)
                .padding(.leading, 28)
            ExpenseRow(log: log3) { print("Tapped") }
        }
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
