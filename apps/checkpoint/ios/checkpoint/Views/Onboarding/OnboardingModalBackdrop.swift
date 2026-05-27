//
//  OnboardingModalBackdrop.swift
//  checkpoint
//
//  Shared chrome for the tour cards that float over the live app UI:
//  a full-screen tap blocker (so taps outside the card are read-only)
//  and a modal accessibility region so VoiceOver focus stays inside the
//  card. Used by both `OnboardingTourOverlay` (anchor-driven spotlight)
//  and `OnboardingTourRecapCard` (centered recap with no spotlight).
//

import SwiftUI

struct OnboardingModalBackdrop: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { }
                .accessibilityHidden(true)
            content
        }
        .accessibilityAddTraits(.isModal)
    }
}

extension View {
    /// Wraps the view in a full-screen tap-blocking, modal-accessibility
    /// backdrop. The view itself sits on top of the blocker and receives
    /// taps normally.
    func onboardingModalBackdrop() -> some View {
        modifier(OnboardingModalBackdrop())
    }
}
