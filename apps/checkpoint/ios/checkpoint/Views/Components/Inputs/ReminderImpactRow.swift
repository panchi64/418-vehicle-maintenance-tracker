//
//  ReminderImpactRow.swift
//  checkpoint
//
//  Shows how an edit would shift a service's next reminder before the user
//  confirms (F9). Uses null grammar ("MAR 12 → NONE") so a change that clears
//  the reminder reads as clearly as one that sets it.
//

import SwiftUI

struct ReminderImpactRow: View {
    let impact: ReminderImpactCalculator.ReminderImpact

    private func label(for schedule: ReminderImpactCalculator.Schedule) -> String {
        if let date = schedule.dueDate {
            return Formatters.shortDate.string(from: date).uppercased()
        }
        if let mileage = schedule.dueMileage {
            return Formatters.mileage(mileage).uppercased()
        }
        return L10n.impactNone.uppercased()
    }

    var body: some View {
        AccessibilityAdaptiveStack {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "arrow.right.circle")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)

                Text(L10n.impactNextReminder.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
            }

            AdaptiveSpacer()

            Text("\(label(for: impact.before)) → \(label(for: impact.after))")
                .font(.brutalistBody)
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.accent.opacity(0.08))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.accent.opacity(0.3), lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: Spacing.lg) {
            ReminderImpactRow(impact: .init(
                before: .init(dueDate: .now, dueMileage: nil),
                after: .init(dueDate: Calendar.current.date(byAdding: .month, value: 6, to: .now), dueMileage: nil)
            ))

            ReminderImpactRow(impact: .init(
                before: .init(dueDate: nil, dueMileage: nil),
                after: .init(dueDate: .now, dueMileage: nil)
            ))
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
