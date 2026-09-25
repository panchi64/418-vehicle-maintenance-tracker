//
//  EmptyStateView.swift
//  checkpoint
//
//  Reusable empty state component with brutalist styling
//

import SwiftUI

/// A reusable empty state view for displaying placeholder content
/// when no data is available. Follows the brutalist design system
/// with zero corner radius and monospace typography.
///
/// Example usage:
/// ```swift
/// EmptyStateView(
///     icon: "wrench.and.screwdriver",
///     title: "No Services",
///     message: "Add your first service to start tracking maintenance.",
///     action: { showAddService = true },
///     actionLabel: "Add Service"
/// )
/// ```
struct EmptyStateView: View {
    /// SF Symbol name for the icon
    let icon: String

    /// Main heading text
    let title: String

    /// Supporting description text (supports multiline)
    let message: String

    /// Optional action callback for the button
    var action: (() -> Void)?

    /// Optional button label (required if action is provided)
    var actionLabel: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon container - brutalist rectangle with accent tint
            ZStack {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(minWidth: 100, minHeight: 100)

                Image(systemName: icon)
                    .font(.largeTitle.weight(.light))
                    .foregroundStyle(Theme.accent)
                    .padding(Spacing.md)
            }
            .fixedSize()
            .accessibilityHidden(true)

            // Text content — one element; the button below stays separate.
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .accessibilityElement(children: .combine)

            // Optional action button
            if let action = action, let actionLabel = actionLabel {
                Button(actionLabel, action: action)
                    .buttonStyle(.primary)
                    // 160pt at standard sizes; full width once the label
                    // can no longer fit in that.
                    .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 160)
                    .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xxl)
    }
}

// MARK: - Previews

#Preview("With Action Button") {
    ZStack {
        AtmosphericBackground()

        EmptyStateView(
            icon: "wrench.and.screwdriver",
            title: "No Services",
            message: "Add your first service to start\ntracking maintenance.",
            action: { print("Add Service tapped") },
            actionLabel: "Add Service"
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Without Action Button") {
    ZStack {
        AtmosphericBackground()

        EmptyStateView(
            icon: "checkmark",
            title: "All Clear",
            message: "No maintenance services scheduled\nfor this vehicle."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("No Vehicle State") {
    ZStack {
        AtmosphericBackground()

        EmptyStateView(
            icon: "car.side.fill",
            title: "No Vehicles",
            message: "Add your first vehicle to start\ntracking maintenance",
            action: { print("Add Vehicle tapped") },
            actionLabel: "Add Vehicle"
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("No Expenses") {
    ZStack {
        AtmosphericBackground()

        EmptyStateView(
            icon: "dollarsign.circle",
            title: "No Expenses",
            message: "Record service costs when\ncompleting maintenance"
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Syncing State") {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            EmptyStateView(
                icon: "icloud.and.arrow.down",
                title: "Syncing Your Data",
                message: "Restoring your vehicles and maintenance\nhistory from iCloud"
            )

            ProgressView()
                .tint(Theme.accent)
        }
    }
    .preferredColorScheme(.dark)
}
