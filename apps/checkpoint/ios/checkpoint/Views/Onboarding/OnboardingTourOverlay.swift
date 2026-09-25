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
//  rest of the UI stays at full opacity. The shared `.onboardingModalBackdrop()`
//  modifier supplies the full-screen tap blocker and modal accessibility region.
//
//  Wayfinding additions vs. the bare anchor overlay:
//      • A `TAB · STEP NN / NN` header pill on every spotlight card so the
//        user knows where they are after tab transitions.
//      • The Next button foreshadows the destination tab on the last step
//        of each tab (`Next: Services →`) so transitions stop being a teleport.
//      • A Back affordance on every step after the first, mirroring forward
//        motion. Back across a tab boundary is a direct rewind — the
//        transition card only narrates forward.
//      • Skip is available immediately on every step, with no confirmation:
//        leaving a tour destroys nothing, and Settings → Replay Tour brings
//        it back.
//

import SwiftUI

struct OnboardingTourOverlay: View {
    let appState: AppState
    @Bindable var onboardingState: OnboardingState
    let anchors: [AnyHashable: Anchor<CGRect>]
    let geometry: GeometryProxy
    let onSkipTour: () -> Void

    private var currentStep: Int {
        onboardingState.currentPhase.tourStep ?? 0
    }

    private var currentTourStep: TourStep? {
        TourStep.at(currentStep)
    }

    private var isLastStep: Bool {
        currentStep >= TourStep.lastIndex
    }

    private var isFirstStep: Bool {
        currentStep == 0
    }

    /// `Done →` on the last spotlight (signals exit from the guided
    /// spotlights — the recap is a brief closer, not another spotlight).
    /// `Next: <destination>` when the next step crosses a tab boundary.
    /// Plain `Next` otherwise.
    private var nextButtonTitle: String {
        if isLastStep { return L10n.commonDone }
        if let next = TourStep.at(currentStep + 1),
           let current = currentTourStep,
           next.tab != current.tab,
           let label = next.transitionLabel?() {
            return L10n.onboardingTourNextTo(label)
        }
        return L10n.commonNext
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
            // Spotlight visuals (only when target's anchor has resolved).
            // Animation scoped to the rect so phase-exit doesn't trigger
            // spurious step-0 animations.
            if let rect = spotlight {
                spotlightVisuals(for: rect)
                    .animation(.easeOut(duration: Theme.animationMedium), value: rect)
            }

            // Tour card — placed dynamically relative to the spotlight,
            // bounded so it can't push off-screen on small devices.
            tourCard(spotlight: spotlight)
        }
        .onboardingModalBackdrop()
        // Fade in once the target anchor is available; fade out if it
        // disappears mid-tour (e.g. brief one-frame race during a tab swap).
        .opacity(spotlight != nil ? 1 : 0)
        .animation(.easeOut(duration: 0.25), value: spotlight != nil)
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
        // `restartKey: currentStep` lets DesignKit's modifier replay the
        // sweep on each step without us re-keying the view tree.
        Color.clear
            .frame(width: rect.width, height: rect.height)
            .shimmer(color: Theme.accent, restartKey: currentStep)
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
                // flanking Spacers. A closing safe-area anchor at the far
                // edge keeps the card clear of the home indicator (below)
                // or Dynamic Island / status bar (above). The fixed-height
                // spotlight-anchor never crosses the spotlight, so the card
                // can't overlap the highlighted element.
                if placeCardBelow(for: rect) {
                    Color.clear.frame(height: rect.maxY + Spacing.lg)
                    Spacer(minLength: 0)
                    fittedCardContent
                    Spacer(minLength: 0)
                    Color.clear.frame(height: geometry.safeAreaInsets.bottom)
                } else {
                    Color.clear.frame(height: geometry.safeAreaInsets.top)
                    Spacer(minLength: 0)
                    fittedCardContent
                    Spacer(minLength: 0)
                    Color.clear.frame(height: geometry.size.height - rect.minY + Spacing.lg)
                }
            } else {
                Spacer()
                fittedCardContent
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    /// At accessibility text sizes the card can outgrow the room beside the
    /// spotlight; it scrolls then instead of clipping its buttons.
    private var fittedCardContent: some View {
        cardContent.scrollingWhenTooTall()
    }

    /// True when there's more usable space below the spotlight than above.
    private func placeCardBelow(for rect: CGRect) -> Bool {
        let availableAbove = rect.minY - geometry.safeAreaInsets.top
        let availableBelow = geometry.size.height - rect.maxY - geometry.safeAreaInsets.bottom
        return availableBelow >= availableAbove
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header pill — TAB · STEP NN / NN. Re-anchors the user after a
            // tab transition: the card answers "where am I" before the user
            // has to look down at the tab bar.
            if let step = currentTourStep {
                Text(L10n.onboardingTourProgress(
                    tab: step.tab.title,
                    step: currentStep + 1,
                    total: TourStep.all.count
                ))
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)
            }

            Text(currentTourStep?.title() ?? "")
                .brutalistLabelStyle(color: Theme.accent)

            Text(currentTourStep?.body() ?? "")
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                // Claim natural vertical size so a tall spotlight (e.g.
                // CostHeadlineCard) can't squeeze the body into an ellipsis.
                .fixedSize(horizontal: false, vertical: true)

            // Primary advance on its own row so the foreshadow label
            // ("Next: Servicios →") never has to compete with Back + Skip
            // for horizontal room on narrow devices.
            // `.primary` owns wrapping and scaling of the label.
            Button {
                onboardingState.advanceTour()
            } label: {
                Text(nextButtonTitle)
            }
            .buttonStyle(.primary)

            // Secondary controls — Back (when not on step 0) on the left,
            // Skip on the right.
            HStack(spacing: Spacing.sm) {
                if !isFirstStep {
                    Button {
                        onboardingState.goBackTour()
                    } label: {
                        Text(L10n.commonBack)
                            .brutalistLabelStyle(color: Theme.textTertiary)
                            .minimumTouchTarget()
                    }
                }

                Spacer()

                OnboardingSkipTourButton(step: currentStep, onSkipTour: onSkipTour)
            }
        }
        // The tour card floats over live colored app UI, so use the
        // near-solid `.opaque` intensity to keep the text fully legible
        // regardless of what's spotlighted behind it.
        .glassCardStyle(intensity: .opaque)
    }
}

/// Leaves the guided tour. Available immediately and unconfirmed: skipping
/// destroys nothing, and Settings → Replay Tour brings the tour back. Shared
/// by the spotlight card and the between-tab transition card so the two
/// can't drift apart again.
struct OnboardingSkipTourButton: View {
    let step: Int
    let onSkipTour: () -> Void

    var body: some View {
        Button {
            AnalyticsService.shared.capture(.onboardingTourSkipped(atStep: step))
            onSkipTour()
        } label: {
            Text(L10n.onboardingSkipTour)
                .brutalistLabelStyle(color: Theme.textTertiary)
                .minimumTouchTarget()
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
                onSkipTour: {}
            )
        }
    }
    .preferredColorScheme(.dark)
}
