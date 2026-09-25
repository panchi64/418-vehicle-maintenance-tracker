//
//  AccessibilityAdaptiveStack.swift
//  checkpoint
//
//  A row of label + value (or icon + text + action) that stacks vertically at
//  accessibility text sizes. At AX5 a 15pt value is ~50pt tall; two of them
//  side by side either truncate or push each other off screen, so the row
//  becomes a leading-aligned column instead (AESTHETIC.md Dynamic Type
//  [REQUIREMENT]).
//
//  Callers that put a `Spacer()` between the halves should use
//  `AdaptiveSpacer()`, which disappears when stacked — a Spacer in a VStack
//  would open a vertical gap instead.
//

import SwiftUI

struct AccessibilityAdaptiveStack<Content: View>: View {
    var horizontalAlignment: VerticalAlignment = .center
    var horizontalSpacing: CGFloat = Spacing.sm
    var verticalSpacing: CGFloat = Spacing.xs
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: verticalSpacing))
            : AnyLayout(HStackLayout(alignment: horizontalAlignment, spacing: horizontalSpacing))

        layout { content }
    }
}

/// A `Spacer` that only exists while `AccessibilityAdaptiveStack` is horizontal.
struct AdaptiveSpacer: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            Spacer(minLength: Spacing.sm)
        }
    }
}
