//
//  OnboardingTourRecapCard.swift
//  checkpoint
//
//  Final tour beat — a centered card with no spotlight, shown after the
//  last anchored step. Ties Home / Services / Costs into a single mental
//  model before handing off to the Get Started full-screen cover. Closes
//  the tour with a story instead of fading on the last spotlight.
//

import SwiftUI

struct OnboardingTourRecapCard: View {
    let onBack: () -> Void
    let onDone: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack {
            Spacer()
            cardContent
            Spacer()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .scrollingWhenTooTall()
        .onboardingModalBackdrop()
    }

    /// Done beside Back at standard sizes; stacked full-width at
    /// accessibility sizes, where a fixed-width Done can't hold its label.
    private var actionLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(L10n.onboardingTourRecapTitle)
                .brutalistLabelStyle(color: Theme.accent)
                .accessibilityAddTraits(.isHeader)

            Text(L10n.onboardingTourRecapBody)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            actionLayout {
                Button {
                    onDone()
                } label: {
                    Text(L10n.onboardingTourRecapDone)
                }
                .buttonStyle(.primary)

                Button {
                    onBack()
                } label: {
                    Text(L10n.commonBack)
                        .brutalistLabelStyle(color: Theme.textTertiary)
                        .minimumTouchTarget()
                }
            }
        }
        .glassCardStyle(intensity: .opaque)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()
        OnboardingTourRecapCard(onBack: {}, onDone: {})
    }
    .preferredColorScheme(.dark)
}
