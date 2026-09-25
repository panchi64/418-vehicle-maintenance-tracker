//
//  AdaptiveStack.swift
//  checkpoint
//
//  A horizontal arrangement that turns vertical at accessibility text sizes.
//

import SwiftUI

/// `HStack` at standard text sizes, `VStack` at accessibility sizes.
///
/// Label-and-value rows, stat tiles, and button pairs are laid out side by
/// side for the default text size. At AX1–AX5 the text is two to three times
/// larger and the same row either truncates or pushes the value off screen,
/// so it stacks instead (DesignSystem/CLAUDE.md → Typography). Using
/// `AnyLayout` rather than two branches keeps child identity, so state and
/// animations survive a text-size change.
///
/// A `Spacer()` between children still works: horizontally it pushes the
/// value trailing; stacked, it collapses to its minimum length.
struct AdaptiveStack<Content: View>: View {
    var horizontalAlignment: HorizontalAlignment = .leading
    var verticalAlignment: VerticalAlignment = .center
    var spacing: CGFloat?
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: horizontalAlignment, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
        layout { content }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        AdaptiveStack {
            Text("DUE AT").font(.brutalistLabel)
            Spacer()
            Text("45,000 mi").font(.brutalistBody)
        }
        AdaptiveStack {
            Text("DUE AT").font(.brutalistLabel)
            Spacer()
            Text("45,000 mi").font(.brutalistBody)
        }
        .dynamicTypeSize(.accessibility3)
    }
    .foregroundStyle(Theme.textPrimary)
    .padding()
    .background(Theme.backgroundPrimary)
}
