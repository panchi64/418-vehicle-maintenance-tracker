//
//  AdaptiveStack.swift
//  checkpoint
//
//  A horizontal arrangement that turns vertical at accessibility text sizes.
//

import SwiftUI

/// `HStack` at standard text sizes, a leading-aligned `VStack` at accessibility
/// sizes.
///
/// Label-and-value rows, stat tiles, and button pairs are laid out side by
/// side for the default text size. At AX1–AX5 the text is two to three times
/// larger and the same row either truncates or pushes the value off screen,
/// so it stacks instead (DesignSystem/CLAUDE.md → Typography, AESTHETIC.md
/// Dynamic Type [REQUIREMENT]). Using `AnyLayout` rather than two branches
/// keeps child identity, so state and animations survive a text-size change.
///
/// `horizontalAlignment` applies when stacked, `verticalAlignment` when side
/// by side. Spacing can differ per axis (`horizontalSpacing` /
/// `verticalSpacing`), or be set for both with `spacing:`.
///
/// To push the trailing half to the edge, put an `AdaptiveSpacer()` between
/// the children: it disappears when stacked. A plain `Spacer()` also works but
/// adds its minimum length as a vertical gap once stacked.
struct AdaptiveStack<Content: View>: View {
    var horizontalAlignment: HorizontalAlignment
    var verticalAlignment: VerticalAlignment
    var horizontalSpacing: CGFloat?
    var verticalSpacing: CGFloat?
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Same spacing on both axes.
    init(
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: spacing,
            verticalSpacing: spacing,
            content: content
        )
    }

    /// Separate spacing for the side-by-side and stacked arrangements.
    init(
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        horizontalSpacing: CGFloat?,
        verticalSpacing: CGFloat?,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content()
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: horizontalAlignment, spacing: verticalSpacing))
            : AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: horizontalSpacing))
        layout { content }
    }
}

/// A `Spacer` that only exists while an `AdaptiveStack` is horizontal — a
/// Spacer in the stacked `VStack` would open a vertical gap instead.
struct AdaptiveSpacer: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            Spacer(minLength: Spacing.sm)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        AdaptiveStack {
            Text("DUE AT").font(.brutalistLabel)
            AdaptiveSpacer()
            Text("45,000 mi").font(.brutalistBody)
        }
        AdaptiveStack {
            Text("DUE AT").font(.brutalistLabel)
            AdaptiveSpacer()
            Text("45,000 mi").font(.brutalistBody)
        }
        .dynamicTypeSize(.accessibility3)
    }
    .foregroundStyle(Theme.textPrimary)
    .padding()
    .background(Theme.backgroundPrimary)
}
