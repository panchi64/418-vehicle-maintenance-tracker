//
//  OnboardingTourTransitionCard.swift
//  checkpoint
//
//  Brief full-overlay card shown between tour steps when the tab changes.
//  Tap-only — the user controls the moment of transition so the tab swap
//  underneath feels like a step they took rather than a teleport.
//

import SwiftUI

struct OnboardingTourTransitionCard: View {
    let targetStep: Int
    let onSkipTour: () -> Void
    let onContinue: () -> Void

    @State private var isVisible = false

    private var sectionName: String {
        TourStep.at(targetStep)?.transitionLabel?() ?? ""
    }

    var body: some View {
        ZStack {
            // Themed scrim rather than black, so light themes don't flash to
            // a dark screen between tabs.
            Theme.backgroundPrimary.opacity(0.95)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: Spacing.md) {
                Spacer()

                // Section name — the fullscreen card is a section divider,
                // not a progress meter, so no step counter here. The spotlight
                // cards still carry the step pill for in-section wayfinding.
                Text(sectionName.uppercased())
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(3)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .opacity(isVisible ? 1 : 0)

                Spacer()

                // The card is tap-anywhere to advance; this is the visible
                // cue, and a real button so VoiceOver and Switch Control have
                // something to activate. Static, no pulse: a repeating
                // animation with no clean teardown was leaking a frame on
                // rapid step changes.
                Button(action: onContinue) {
                    HStack(spacing: Spacing.sm) {
                        Text(L10n.onboardingTransitionTapToContinue.uppercased())
                            .font(.brutalistLabel)
                            .tracking(2)
                            .multilineTextAlignment(.center)

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(Theme.textTertiary)
                    .minimumTouchTarget()
                }
                .buttonStyle(.plain)
                .opacity(isVisible ? 0.7 : 0)

                OnboardingSkipTourButton(step: targetStep, onSkipTour: onSkipTour)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
                    .opacity(isVisible ? 1 : 0)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onContinue)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    OnboardingTourTransitionCard(
        targetStep: 2,
        onSkipTour: {},
        onContinue: {}
    )
    .preferredColorScheme(.dark)
}
