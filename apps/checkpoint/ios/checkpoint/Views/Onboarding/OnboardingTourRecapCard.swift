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

    var body: some View {
        VStack {
            Spacer()
            cardContent
            Spacer()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .onboardingModalBackdrop()
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(L10n.onboardingTourRecapTitle)
                .brutalistLabelStyle(color: Theme.accent)

            Text(L10n.onboardingTourRecapBody)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Button {
                    onDone()
                } label: {
                    Text(L10n.onboardingTourRecapDone)
                }
                .buttonStyle(.primary)
                .frame(width: 140)

                Spacer()

                Button {
                    onBack()
                } label: {
                    Text(L10n.commonBack)
                        .brutalistLabelStyle(color: Theme.textTertiary)
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
