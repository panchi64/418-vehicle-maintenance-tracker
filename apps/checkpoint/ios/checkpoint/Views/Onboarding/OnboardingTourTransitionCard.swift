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
    @State private var showSkipConfirm = false

    private var sectionName: String {
        TourStep.at(targetStep)?.transitionLabel?() ?? ""
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Spacer()

                // Section name — the fullscreen card is a section divider,
                // not a progress meter, so no step counter here. The spotlight
                // cards still carry the step pill for in-section wayfinding.
                Text(sectionName.uppercased())
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(3)
                    .opacity(isVisible ? 1 : 0)

                Spacer()

                // Tap-to-continue affordance — the card is tap-anywhere to
                // advance; this is the visible cue. Static, no pulse: a
                // repeating animation with no clean teardown was leaking
                // a frame on rapid step changes.
                HStack(spacing: Spacing.sm) {
                    Text(L10n.onboardingTransitionTapToContinue.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .opacity(isVisible ? 0.7 : 0)

                // Skip Tour — same confirmation guard as the spotlight card
                // so the easier-to-fat-finger surface doesn't bypass it.
                Button {
                    AnalyticsService.shared.capture(
                        .onboardingTourSkipped(atStep: targetStep)
                    )
                    showSkipConfirm = true
                } label: {
                    Text(L10n.onboardingSkipTour)
                        .brutalistLabelStyle(color: Theme.textTertiary)
                }
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
                .opacity(isVisible ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Skip the tap-to-continue if the Skip alert is up — the
            // alert owns the user's attention.
            guard !showSkipConfirm else { return }
            onContinue()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                isVisible = true
            }
        }
        .alert(
            L10n.onboardingTourSkipConfirmTitle,
            isPresented: $showSkipConfirm
        ) {
            Button(L10n.onboardingSkipTour, role: .destructive) {
                onSkipTour()
            }
            Button(L10n.onboardingTourSkipConfirmCancel, role: .cancel) { }
        } message: {
            Text(L10n.onboardingTourSkipConfirmMessage)
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
