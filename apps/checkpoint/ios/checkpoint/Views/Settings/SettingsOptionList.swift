//
//  SettingsOptionList.swift
//  checkpoint
//
//  The single-choice list behind every Settings picker (distance unit,
//  climate zone, due-soon thresholds, bundling windows). One component so
//  selection reads the same everywhere:
//  a checkmark for sight, the `.isSelected` trait for VoiceOver.
//

import SwiftUI

struct SettingsOptionList<Option: Hashable>: View {
    let options: [Option]
    let selection: Option?
    let title: (Option) -> String
    var subtitle: (Option) -> String? = { _ in nil }
    let onSelect: (Option) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                if index > 0 {
                    SettingsRowDivider()
                }
                SettingsOptionRow(
                    title: title(option),
                    subtitle: subtitle(option),
                    isSelected: option == selection
                ) {
                    onSelect(option)
                }
            }
        }
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }
}

struct SettingsOptionRow: View {
    let title: String
    var subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.md)
            .frame(minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The pushed screen every Settings picker shares: an explanatory caption
/// over the option list, scrolling so long zone descriptions survive
/// accessibility text sizes.
struct SettingsPickerScreen<Content: View>: View {
    let title: String
    var caption: String?
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let caption {
                        Text(caption)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    content
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.lg)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The rule between rows inside a Settings group.
struct SettingsRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.gridLine)
            .frame(height: Theme.borderWidth)
            .accessibilityHidden(true)
    }
}

/// A Settings section, shaped like the system's grouped list: a Title Case
/// header, the rows in one bordered group, and an optional footer that says
/// what the group's settings do. Every group looks the same — a Switchboard's
/// rows are equal and independent, so no group may out-rank another.
struct SettingsGroup<Content: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.brutalistSectionTitle)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                content
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()

            if let footer {
                Text(footer)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        SettingsOptionList(
            options: DueSoonSettings.daysOptions,
            selection: 30,
            title: { "\($0)" },
            subtitle: { $0 == 30 ? L10n.dueSoonDefault : nil },
            onSelect: { _ in }
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
