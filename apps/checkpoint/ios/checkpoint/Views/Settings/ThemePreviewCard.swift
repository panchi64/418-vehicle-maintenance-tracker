//
//  ThemePreviewCard.swift
//  checkpoint
//
//  Card showing theme preview with color swatches
//

import SwiftUI

struct ThemePreviewCard: View {
    let theme: ThemeDefinition
    let isActive: Bool
    let isOwned: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Color swatches
            HStack(spacing: 4) {
                ForEach(theme.previewColors, id: \.self) { hex in
                    Rectangle()
                        .fill(Color(hex: hex))
                        .frame(width: 24, height: 24)
                }
            }

            // Theme info
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.displayName)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                Text(theme.tier.rawValue.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(tierColor)
                    .tracking(1)
            }

            Spacer()

            // Status indicator
            if isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.accent)
            } else if !isOwned {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(
                    isActive ? Theme.accent : Theme.gridLine,
                    lineWidth: Theme.borderWidth
                )
        )
    }

    private var tierColor: Color {
        switch theme.tier {
        case .free: return Theme.textTertiary
        case .pro: return Theme.accent
        case .rare: return Theme.statusGood
        }
    }
}
