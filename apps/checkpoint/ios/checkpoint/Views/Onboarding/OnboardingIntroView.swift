//
//  OnboardingIntroView.swift
//  checkpoint
//
//  Step 1 of 4: one welcome page. What the app does, the one preference the
//  app can't infer and every number depends on (distance unit), and the way
//  into the tour. Skip is always in the corner.
//
//  The second page (unit + climate zone) is gone: the climate zone only
//  tunes seasonal reminders, is in Settings, and a scrolling list of zones is
//  not a "short step".
//

import SwiftUI

struct OnboardingIntroView: View {
    let onStartTour: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            AtmosphericBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        Text(L10n.onboardingSkip)
                            .brutalistLabelStyle(color: Theme.textTertiary)
                            .minimumTouchTarget()
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)

                welcomeContent

                Button {
                    onStartTour()
                } label: {
                    Text(L10n.onboardingLetsLook)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var welcomeContent: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: Spacing.lg)

            VStack(spacing: Spacing.sm) {
                Text(L10n.onboardingWelcomeTitle)
                    .brutalistTitleStyle()
                    .revealAnimation(delay: 0.2)

                Text(L10n.onboardingWelcomeSubtitle)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .revealAnimation(delay: 0.3)
            }

            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
                .padding(.vertical, Spacing.xs)
                .revealAnimation(delay: 0.4)

            VStack(alignment: .leading, spacing: Spacing.lg) {
                featureRow(number: "01", title: L10n.onboardingFeature1Title, body: L10n.onboardingFeature1Body, index: 0)
                featureRow(number: "02", title: L10n.onboardingFeature2Title, body: L10n.onboardingFeature2Body, index: 1)
                featureRow(number: "03", title: L10n.onboardingFeature3Title, body: L10n.onboardingFeature3Body, index: 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Every mileage, interval and cost-per-distance reads in this
            // unit, and the locale can't settle it (a US-built car in PR).
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(L10n.onboardingDistanceUnit.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                InstrumentSegmentedControl(
                    options: DistanceUnit.allCases,
                    selection: Binding(
                        get: { DistanceSettings.shared.unit },
                        set: { DistanceSettings.shared.unit = $0 }
                    ),
                    labelFor: { $0.displayName }
                )
            }
            .staggeredReveal(index: 3, baseDelay: 0.1)

            Spacer(minLength: Spacing.lg)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .scrollingWhenTooTall()
    }

    private func featureRow(number: String, title: String, body: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text(number)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.accent)
                .tracking(1.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textPrimary)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(body)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .staggeredReveal(index: index, baseDelay: 0.1)
    }
}

#Preview {
    OnboardingIntroView(onStartTour: {}, onSkip: {})
        .preferredColorScheme(.dark)
}
