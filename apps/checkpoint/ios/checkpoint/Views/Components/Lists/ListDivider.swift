//
//  ListDivider.swift
//  checkpoint
//
//  Reusable list divider with consistent brutalist styling
//

import SwiftUI

/// The rule between two rows in a list.
///
/// Full width by default. It used to inset 56pt to clear a row icon, which only
/// made sense while the list sat inside a bordered card — the card's edge was
/// what told you where the list began, so the divider was free to start late.
/// Without the card the divider IS the list's structure, and a partial rule left
/// each row looking as though it began somewhere different from its heading.
///
/// `leadingPadding` survives for callers that genuinely want a hanging indent,
/// but the default is now flush.
struct ListDivider: View {
    var leadingPadding: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Theme.gridLine)
            .frame(height: 1)
            .padding(.leading, leadingPadding)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: 0) {
            // Sample list item
            HStack(spacing: Spacing.md) {
                Rectangle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Rectangle()
                            .fill(Theme.accent)
                            .frame(width: 8, height: 8)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("OIL CHANGE")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                    Text("500 MI")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.listItem)

            ListDivider()

            // Another sample list item
            HStack(spacing: Spacing.md) {
                Rectangle()
                    .fill(Theme.statusGood.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Rectangle()
                            .fill(Theme.statusGood)
                            .frame(width: 8, height: 8)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("TIRE ROTATION")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                    Text("2,500 MI")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.listItem)

            ListDivider()

            // Full-width divider example
            HStack(spacing: Spacing.md) {
                Rectangle()
                    .fill(Theme.statusDueSoon.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Rectangle()
                            .fill(Theme.statusDueSoon)
                            .frame(width: 8, height: 8)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("BRAKE INSPECTION")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                    Text("DUE SOON")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.listItem)
        }
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .screenPadding()
    }
    .preferredColorScheme(.dark)
}
