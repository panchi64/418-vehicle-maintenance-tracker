//
//  ReadoutSection.swift
//  checkpoint
//
//  The section shell for Readout surfaces — Home, Costs, Services, detail views.
//
//  Why this exists: readout screens were assembled from bare VStacks in which
//  every datum landed in the same 11–15pt band, so a screen with nine sections
//  and thirty values had no reading order. The app's hero cards work precisely
//  because they commit to one dominant element; this type makes that structure
//  the default for ordinary sections too.
//
//  The API is deliberately opinionated: `primary` is a single non-optional
//  slot, so a section cannot be built without deciding what its most important
//  element is. Supporting content is separate and recedes. If you find
//  yourself wanting two primaries, the section is doing two jobs — split it.
//
//  See docs/SURFACE_DOCTRINE.md, Part 2 → "Readout rules".
//

import SwiftUI

struct ReadoutSection<Primary: View, Supporting: View, Action: View>: View {
    let title: String

    /// Trailing header affordance — "View All", "Export". Must navigate to a
    /// list that actually contains the items this section showed (rule 4).
    let action: Action

    /// The one most important element. Not optional, by design.
    let primary: Primary

    /// Detail that supports the primary without competing with it.
    let supporting: Supporting

    init(
        title: String,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder supporting: () -> Supporting = { EmptyView() },
        @ViewBuilder action: () -> Action = { EmptyView() }
    ) {
        self.title = title
        self.primary = primary()
        self.supporting = supporting()
        self.action = action()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: title) {
                action
            }

            primary

            // Supporting content is separated by a full step of spacing rather
            // than a divider: proximity carries grouping, and a rule here
            // would imply the two halves are peers.
            supporting
                .padding(.top, Spacing.xs)
        }
    }
}

// MARK: - Header action

/// The one style for a section's trailing affordance. Uses a full 44pt touch
/// target despite its small type, since it sits beside a header and would
/// otherwise be a sub-target tap.
struct ReadoutSectionAction: View {
    let label: String
    var systemImage: String?
    let action: () -> Void

    init(label: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.label = label
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(label.uppercased())
                    .font(.brutalistLabel)
                    .tracking(1)
            }
            .foregroundStyle(Theme.accent)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()

        ScrollView {
            VStack(spacing: Spacing.xl) {
                ReadoutSection(title: "Next Up") {
                    // Primary: one dominant value.
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("1,200 mi")
                            .font(.brutalistTitle)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Oil change")
                            .font(.brutalistBodyEmphasis)
                            .foregroundStyle(Theme.textPrimary)
                    }
                } supporting: {
                    Text("Due Mar 12 · last done 4 months ago")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                } action: {
                    ReadoutSectionAction(label: "View All") {}
                }

                ReadoutSection(title: "Spending") {
                    Text("$1,847")
                        .font(.brutalistTitle)
                        .foregroundStyle(Theme.accent)
                } supporting: {
                    Text("Across 12 services this year")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
