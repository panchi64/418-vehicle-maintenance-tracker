//
//  OnboardingTourTransitionCard.swift
//  checkpoint
//
//  Brief full-overlay card shown between tour steps when the tab changes
//

import SwiftUI

struct OnboardingTourTransitionCard: View {
    let targetStep: Int
    let onSkipTour: () -> Void
    let onContinue: () -> Void

    @State private var isVisible = false

    private var sectionNumber: String {
        String(format: "%02d", targetStep + 1)
    }

    private var sectionName: String {
        switch targetStep {
        case 2: return L10n.onboardingTransitionServices
        case 3: return L10n.onboardingTransitionCosts
        default: return ""
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Spacer()

                // Section number + name
                VStack(spacing: Spacing.sm) {
                    Text("\(sectionNumber) //")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(2)

                    Text(sectionName.uppercased())
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(3)
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.95)

                Spacer()

                // Skip Tour
                Button {
                    onSkipTour()
                } label: {
                    Text(L10n.onboardingSkipTour)
                        .brutalistLabelStyle(color: Theme.textTertiary)
                }
                .padding(.bottom, Spacing.xl)
                .opacity(isVisible ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onContinue()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                isVisible = true
            }
            // Auto-advance after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onContinue()
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
