//
//  ListDivider.swift
//  checkpoint
//
//  Reusable list divider with consistent brutalist styling
//

import SwiftUI

struct ListDivider: View {
    var leadingPadding: CGFloat = 56  // Default matches icon + spacing

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
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
        .screenPadding()
    }
    .preferredColorScheme(.dark)
}
