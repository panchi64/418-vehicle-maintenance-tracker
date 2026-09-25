//
//  SettingsActionRow.swift
//  checkpoint
//
//  Row building blocks for the Settings groups: an action row (title,
//  optional subtitle, trailing icon) and a value row (title, current value,
//  disclosure chevron). Both keep a 44pt minimum height and stack their
//  columns at accessibility text sizes instead of squeezing them.
//

import SwiftUI

/// Title + optional subtitle with a trailing symbol. Used directly as a
/// `NavigationLink` label, or wrapped in a button by `SettingsActionRow`.
struct SettingsRowLabel: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var iconColor: Color = Theme.accent

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .frame(minHeight: TouchTarget.minimum)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct SettingsActionRow: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var iconColor: Color = Theme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowLabel(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                iconColor: iconColor
            )
        }
        .buttonStyle(.plain)
    }
}

/// Title with the setting's current value and a disclosure chevron — the
/// label of a row that pushes a picker.
struct SettingsValueRow: View {
    let title: String
    let value: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // At accessibility sizes the value moves under the title; side
            // by side, a long title and value each got half a line and wrapped
            // one word per row.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                : AnyLayout(HStackLayout(spacing: Spacing.sm))

            layout {
                Text(title)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(value)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .frame(minHeight: TouchTarget.minimum)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
