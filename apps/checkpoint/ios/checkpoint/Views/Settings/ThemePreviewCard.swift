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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Swatches sit above the name at accessibility sizes so the name
        // keeps the full row width.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))

        HStack(spacing: Spacing.sm) {
            layout {
                HStack(spacing: 4) {
                    ForEach(theme.previewColors, id: \.self) { hex in
                        Rectangle()
                            .fill(Color(hex: hex))
                            .frame(width: 24, height: 24)
                    }
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text(tierName)
                        .font(.brutalistLabel)
                        .foregroundStyle(tierColor)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Status indicator — the symbol differs (check vs lock), and
            // VoiceOver hears the same state through the traits and value.
            if isActive {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            } else if !isOwned {
                Image(systemName: "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(Spacing.md)
        .frame(minHeight: TouchTarget.minimum)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(
                    isActive ? Theme.accent : Theme.gridLine,
                    lineWidth: Theme.borderWidth
                )
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityValue(isOwned ? "" : L10n.settingsThemeLocked)
    }

    private var tierName: String {
        switch theme.tier {
        case .free: return L10n.settingsThemeTierFree
        case .pro: return L10n.settingsThemeTierPro
        case .rare: return L10n.settingsThemeTierRare
        }
    }

    private var tierColor: Color {
        switch theme.tier {
        case .free: return Theme.textTertiary
        case .pro: return Theme.accent
        case .rare: return Theme.statusGood
        }
    }
}
