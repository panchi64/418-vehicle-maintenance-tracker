//
//  OnboardingTourOverlay.swift
//  checkpoint
//
//  Phase 2 of onboarding — anchor-driven spotlight overlay.
//
//  The host (ContentView) resolves component anchors via
//  `overlayPreferenceValue(SpotlightAnchorPreferenceKey.self)` and hands them
//  to this view alongside a coordinating `GeometryProxy`. The spotlight is
//  composed from the existing brutalist primitives:
//
//      • Off-white underglow (a stronger variant of `StatusGlowModifier`)
//      • Subtle diagonal `shimmer` sweep
//      • 2px sharp-cornered accent frame outset slightly from the target
//
//  No screen-wide dim. Focus is carried by the frame + glow + shimmer; the
//  rest of the UI stays at full opacity. The full-screen `Color.clear` tap
//  blocker keeps the tour read-only and `.accessibilityAddTraits(.isModal)`
//  scopes VoiceOver focus to the overlay's card.
//

import SwiftUI

struct OnboardingTourOverlay: View {
    let appState: AppState
    @Bindable var onboardingState: OnboardingState
    let anchors: [AnyHashable: Anchor<CGRect>]
    let geometry: GeometryProxy
    let onSkipTour: () -> Void
    let onTourComplete: () -> Void

    private var currentStep: Int {
        onboardingState.currentPhase.tourStep ?? 0
    }

    private var currentTourStep: TourStep? {
        TourStep.at(currentStep)
    }

    private func resolvedSpotlight() -> CGRect? {
        guard let target = currentTourStep?.target,
              let anchor = anchors.anchor(target) else { return nil }
        return geometry[anchor]
    }

    var body: some View {
        // Resolve once per body pass — body, placement, and visuals all reuse it.
        let spotlight = resolvedSpotlight()

        ZStack {
            // 1. Tap blocker — read-only tour. Hidden from VoiceOver so the
            //    overlay card takes focus.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { }
                .accessibilityHidden(true)

            // 2. Spotlight visuals (only when target's anchor has resolved).
            //    Animation scoped to the rect so phase-exit doesn't trigger
            //    spurious step-0 animations.
            if let rect = spotlight {
                spotlightVisuals(for: rect)
                    .animation(.easeOut(duration: Theme.animationMedium), value: rect)
            }

            // 3. Tour card — placed dynamically relative to the spotlight,
            //    bounded so it can't push off-screen on small devices.
            tourCard(spotlight: spotlight)
        }
        // Fade in once the target anchor is available; fade out if it
        // disappears mid-tour (e.g. brief one-frame race during a tab swap).
        .opacity(spotlight != nil ? 1 : 0)
        .animation(.easeOut(duration: 0.25), value: spotlight != nil)
        // Modal accessibility region — VoiceOver focus stays inside the
        // overlay card and doesn't reach the spotlighted (tap-blocked) UI.
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Spotlight visuals

    /// Outset around the captured anchor bounds so the highlighted element
    /// has visual breathing room from the frame.
    private let spotlightOutset: CGFloat = 6

    @ViewBuilder
    private func spotlightVisuals(for anchorRect: CGRect) -> some View {
        let rect = anchorRect.insetBy(dx: -spotlightOutset, dy: -spotlightOutset)

        // Underglow — a stroked rectangle so the glow emanates outward from
        // the edges rather than filling the area behind the highlighted
        // element. Wide stroke + blur creates a soft halo around the frame.
        Rectangle()
            .stroke(Theme.accent, lineWidth: 10)
            .frame(width: rect.width, height: rect.height)
            .blur(radius: 18)
            .opacity(0.55)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

        // Shimmer — subtle diagonal off-white sweep masked to the rect.
        // `.id(currentStep)` re-creates the overlay each step so its
        // `.onAppear`-driven animation restarts (otherwise the sweep only
        // plays for the first spotlighted element).
        Color.clear
            .frame(width: rect.width, height: rect.height)
            .shimmer(color: Theme.accent)
            .id(currentStep)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

        // Brutalist frame — 2px stroke, sharp 90° corners. `.strokeBorder`
        // keeps the line entirely inside the rect's bounds, matching the
        // inset rhythm of the app's other accent borders.
        Rectangle()
            .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Tour card

    @ViewBuilder
    private func tourCard(spotlight: CGRect?) -> some View {
        VStack(spacing: 0) {
            if let rect = spotlight {
                // Anchor the card to the side of the spotlight that has more
                // available room, then center it within that region with
                // flanking spacers. This keeps the card visually balanced in
                // the largest free area while guaranteeing it never overlaps
                // the spotlight (the fixed-height anchor sits right at
                // rect.maxY + lg or rect.minY - lg).
                if placeCardBelow(for: rect) {
                    Color.clear.frame(height: rect.maxY + Spacing.lg)
                    Spacer(minLength: 0)
                    cardContent
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                    cardContent
                    Spacer(minLength: 0)
                    Color.clear.frame(height: geometry.size.height - rect.minY + Spacing.lg)
                }
            } else {
                Spacer()
                cardContent
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    /// True when there's more usable space below the spotlight than above.
    private func placeCardBelow(for rect: CGRect) -> Bool {
        let availableAbove = rect.minY - geometry.safeAreaInsets.top
        let availableBelow = geometry.size.height - rect.maxY - geometry.safeAreaInsets.bottom
        return availableBelow >= availableAbove
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(currentTourStep?.title() ?? "")
                .brutalistLabelStyle(color: Theme.accent)

            Text(currentTourStep?.body() ?? "")
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Button {
                    if currentStep < TourStep.lastIndex {
                        onboardingState.advanceTour()
                    } else {
                        onTourComplete()
                    }
                } label: {
                    Text(currentStep < TourStep.lastIndex ? L10n.commonNext : L10n.commonDone)
                }
                .buttonStyle(.primary)
                .frame(width: 120)

                Spacer()

                Button {
                    onSkipTour()
                } label: {
                    Text(L10n.onboardingSkipTour)
                        .brutalistLabelStyle(color: Theme.textTertiary)
                }
            }
        }
        .padding(Theme.cardPadding)
        .background(tourCardBackground)
        .brutalistBorder()
    }

    /// Dedicated frosted-glass plate for the tour card. The standard
    /// `glassCardStyle` lets too much of the underlying app UI through to
    /// stay legible while a colored component is spotlighted — so we stack
    /// `.ultraThickMaterial` over an opaque background-primary plate. The
    /// material handles the frosted look; the plate guarantees the text
    /// always sits on a near-solid surface.
    private var tourCardBackground: some View {
        ZStack {
            Rectangle().fill(Theme.backgroundPrimary)
            Rectangle().fill(.ultraThickMaterial)
            Rectangle().fill(Theme.backgroundPrimary.opacity(0.5))
        }
    }
}

#Preview {
    GeometryReader { geo in
        ZStack {
            AtmosphericBackground()

            OnboardingTourOverlay(
                appState: AppState(),
                onboardingState: OnboardingState(),
                anchors: [:],
                geometry: geo,
                onSkipTour: {},
                onTourComplete: {}
            )
        }
    }
    .preferredColorScheme(.dark)
}
