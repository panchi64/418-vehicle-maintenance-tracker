//
//  SeasonalReminderCard.swift
//  checkpoint
//
//  Brutalist card showing a seasonal maintenance advisory with actions
//

import SwiftUI

struct SeasonalReminderCard: View {
    let reminder: SeasonalReminder
    let onScheduleService: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row: icon + label
            HStack(alignment: .top) {
                Image(systemName: reminder.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text("SEASONAL ADVISORY")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1.5)

                    Text(reminder.name.uppercased())
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                        .textCase(.uppercase)
                }

                Spacer()
            }
            .padding(.bottom, Spacing.listItem)

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Description
            Text(reminder.description)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .padding(.vertical, Spacing.listItem)

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Action buttons
            HStack(spacing: Spacing.sm) {
                Button {
                    onScheduleService()
                } label: {
                    Text("SCHEDULE SERVICE")
                }
                .buttonStyle(.primary)

                Button {
                    onDismiss()
                } label: {
                    Text("NOT THIS YEAR")
                }
                .buttonStyle(.secondary)
            }
            .padding(.top, Spacing.listItem)
        }
        .glassCardStyle(intensity: .subtle)
        .contextMenu {
            Button(role: .destructive) {
                SeasonalSettings.shared.suppressPermanently(reminder.id)
            } label: {
                Label("Don't Show Again", systemImage: "eye.slash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Seasonal advisory, \(reminder.name)")
        .accessibilityHint("Schedule this service or dismiss until next year")
    }
}

#Preview {
    let reminder = SeasonalReminder.allReminders.first { $0.id == "winterTires" }!

    return ZStack {
        AtmosphericBackground()

        SeasonalReminderCard(
            reminder: reminder,
            onScheduleService: { print("Schedule") },
            onDismiss: { print("Dismiss") }
        )
        .padding(Theme.screenHorizontalPadding)
    }
    .preferredColorScheme(.dark)
}
