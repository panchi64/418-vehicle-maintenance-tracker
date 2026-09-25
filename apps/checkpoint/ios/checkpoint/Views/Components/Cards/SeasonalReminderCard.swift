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
            // Header and description read as one element; the two action
            // buttons below stay separate so VoiceOver can reach each.
            VStack(alignment: .leading, spacing: 0) {
                // Header row: icon + label
                HStack(alignment: .top) {
                    Image(systemName: reminder.icon)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)

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
            }
            .accessibilityElement(children: .combine)

            // Divider
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)

            // Action buttons
            AdaptiveStack(spacing: Spacing.sm) {
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
