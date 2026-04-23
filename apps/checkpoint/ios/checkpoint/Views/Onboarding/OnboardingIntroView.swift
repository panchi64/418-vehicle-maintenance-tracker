//
//  OnboardingIntroView.swift
//  checkpoint
//
//  Phase 1: Full-screen intro pages — Welcome and Preferences (Distance Unit + Climate Zone)
//

import SwiftUI

struct OnboardingIntroView: View {
    @Bindable var onboardingState: OnboardingState
    let onStartTour: () -> Void
    let onSkip: () -> Void

    @State private var currentPage = 0
    @State private var selectedClimateZone: ClimateZone? = SeasonalSettings.shared.climateZone

    var body: some View {
        ZStack {
            AtmosphericBackground()

            VStack(spacing: 0) {
                // Skip button — top right
                HStack {
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        Text(L10n.onboardingSkip)
                            .brutalistLabelStyle(color: Theme.textTertiary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)

                // Paged content
                TabView(selection: $currentPage) {
                    welcomePageContent
                        .tag(0)

                    preferencesPageContent
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Fixed bottom area — step indicator always in same position
                VStack(spacing: Spacing.md) {
                    if currentPage == 0 {
                        HStack(spacing: Spacing.xs) {
                            Text(L10n.onboardingSwipeNext)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1.5)
                                .textCase(.uppercase)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    } else {
                        Button {
                            onStartTour()
                        } label: {
                            Text(L10n.onboardingLetsLook)
                        }
                        .buttonStyle(.primary)
                    }

                    StepIndicator(currentStep: currentPage + 1, totalSteps: 2)
                }
                .animation(.easeOut(duration: Theme.animationMedium), value: currentPage)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Page 1: Welcome + Features

    private var welcomePageContent: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Title block
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

            // Feature list
            VStack(alignment: .leading, spacing: Spacing.lg) {
                featureRow(
                    number: "01",
                    title: L10n.onboardingFeature1Title,
                    body: L10n.onboardingFeature1Body,
                    index: 0
                )

                featureRow(
                    number: "02",
                    title: L10n.onboardingFeature2Title,
                    body: L10n.onboardingFeature2Body,
                    index: 1
                )

                featureRow(
                    number: "03",
                    title: L10n.onboardingFeature3Title,
                    body: L10n.onboardingFeature3Body,
                    index: 2
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Page 2: Preferences (Distance Unit + Climate Zone)

    private var preferencesPageContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Distance Unit
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.onboardingDistanceUnit)

                    Text(L10n.onboardingDistanceUnitExplanation)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textSecondary)

                    InstrumentSegmentedControl(
                        options: DistanceUnit.allCases,
                        selection: Binding(
                            get: { DistanceSettings.shared.unit },
                            set: { DistanceSettings.shared.unit = $0 }
                        ),
                        labelFor: { $0.displayName }
                    )
                }

                // Climate Zone
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.onboardingClimateZone)

                    Text(L10n.onboardingClimateZoneExplanation)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textSecondary)

                    VStack(spacing: 0) {
                        ForEach(ClimateZone.allCases, id: \.self) { zone in
                            climateZoneRow(for: zone)

                            if zone != ClimateZone.allCases.last {
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: Theme.borderWidth)
                            }
                        }
                    }
                    .background(Theme.surfaceInstrument)
                    .brutalistBorder()
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xl)
        }
    }

    private func climateZoneRow(for zone: ClimateZone) -> some View {
        Button {
            selectedClimateZone = zone
            SeasonalSettings.shared.climateZone = zone
            HapticService.shared.selectionChanged()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(zone.displayName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text(zone.description)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedClimateZone == zone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Feature Row

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
    OnboardingIntroView(
        onboardingState: OnboardingState(),
        onStartTour: {},
        onSkip: {}
    )
    .preferredColorScheme(.dark)
}
