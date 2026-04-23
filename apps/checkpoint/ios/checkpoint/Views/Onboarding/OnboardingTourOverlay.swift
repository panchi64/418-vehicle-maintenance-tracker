//
//  OnboardingTourOverlay.swift
//  checkpoint
//
//  Phase 2: Guided tour overlay with spotlight cutouts and floating explanation cards
//

import SwiftUI

// MARK: - Spotlight Cutout Shape

/// Even-odd fill shape that creates a transparent hole in the dimmed overlay
private struct SpotlightCutout: Shape {
    var spotlight: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRect(spotlight)
        return path
    }
}

// MARK: - Tour Overlay

struct OnboardingTourOverlay: View {
    let appState: AppState
    @Bindable var onboardingState: OnboardingState
    let onSkipTour: () -> Void
    let onTourComplete: () -> Void

    @State private var isVisible = false
    @State private var pulseOpacity: Double = 1.0

    private var currentStep: Int {
        onboardingState.currentPhase.tourStep ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            let spotlight = spotlightRect(for: currentStep, in: geometry)

            ZStack {
                // 1. Dimmed backdrop with spotlight cutout
                Color.black.opacity(0.85)
                    .mask(
                        SpotlightCutout(spotlight: spotlight)
                            .fill(style: FillStyle(eoFill: true))
                    )
                    .opacity(isVisible ? 1 : 0)

                // 2. Tap blocker — catches taps that fall through the spotlight hole
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { }

                // 3. Accent border around spotlight (non-interactive)
                Rectangle()
                    .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
                    .frame(width: spotlight.width, height: spotlight.height)
                    .position(x: spotlight.midX, y: spotlight.midY)
                    .opacity(isVisible ? pulseOpacity : 0)
                    .allowsHitTesting(false)

                // 4. Tour card (topmost — receives taps)
                tourCard(spotlight: spotlight, geometry: geometry)
            }
        }
        .onChange(of: onboardingState.currentPhase) { _, newPhase in
            if case .tour(let step) = newPhase {
                // Fade out
                withAnimation(.easeIn(duration: 0.12)) {
                    isVisible = false
                }

                // Switch tab (for same-tab transitions)
                withAnimation(.easeInOut(duration: Theme.animationMedium)) {
                    switch step {
                    case 0, 1:
                        appState.selectedTab = .home
                    case 2:
                        appState.selectedTab = .services
                    case 3:
                        appState.selectedTab = .costs
                    default:
                        break
                    }
                }

                // Fade in at new position
                withAnimation(.easeOut(duration: 0.2).delay(0.2)) {
                    isVisible = true
                }
            }
        }
        .onAppear {
            // Only reset tab on initial tour start; after transitions the tab is already correct
            if onboardingState.currentPhase == .tour(step: 0) {
                appState.selectedTab = .home
            }
            withAnimation(.easeOut(duration: 0.25).delay(0.2)) {
                isVisible = true
            }
            // Start pulse animation
            withAnimation(
                .easeInOut(duration: Theme.pulseAnimationDuration)
                .repeatForever(autoreverses: true)
            ) {
                pulseOpacity = 0.4
            }
        }
    }

    // MARK: - Tour Card

    private func tourCard(spotlight: CGRect, geometry: GeometryProxy) -> some View {
        VStack {
            if currentStep == 1 {
                // Header spotlight: card below the header
                Spacer()
                    .frame(height: spotlight.maxY + Spacing.md)
                cardContent
                Spacer()
            } else {
                // Content spotlight: card at bottom, above tab bar
                Spacer()
                cardContent
                    .padding(.bottom, 90)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(stepTitle)
                .brutalistLabelStyle(color: Theme.accent)

            Text(stepBody)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Button {
                    if currentStep < 3 {
                        onboardingState.advanceTour()
                    } else {
                        onTourComplete()
                    }
                } label: {
                    Text(currentStep < 3 ? L10n.commonNext : L10n.commonDone)
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
        .glassCardStyle(intensity: .heavy)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Spotlight Positioning
    // All rects in content-area coordinates (y=0 = top of safe content area)

    private func spotlightRect(for step: Int, in geometry: GeometryProxy) -> CGRect {
        let screenW = geometry.size.width
        // VehicleHeader: Spacing.sm (8pt) top padding + ~72pt content
        let headerBottom: CGFloat = Spacing.sm + 72
        let tabBarHeight: CGFloat = 72
        let contentHeight = geometry.size.height - headerBottom - tabBarHeight
        let horizontalInset = Spacing.screenHorizontal

        switch step {
        case 0: // Dashboard — highlight top portion of content area
            return CGRect(
                x: horizontalInset,
                y: headerBottom + Spacing.sm,
                width: screenW - 2 * horizontalInset,
                height: min(contentHeight * 0.45, 300)
            )
        case 1: // Vehicle Header — highlight the header itself
            return CGRect(
                x: 0,
                y: 0,
                width: screenW,
                height: headerBottom
            )
        case 2: // Services — highlight content area
            return CGRect(
                x: horizontalInset,
                y: headerBottom + Spacing.sm,
                width: screenW - 2 * horizontalInset,
                height: min(contentHeight * 0.55, 350)
            )
        case 3: // Costs — highlight content area
            return CGRect(
                x: horizontalInset,
                y: headerBottom + Spacing.sm,
                width: screenW - 2 * horizontalInset,
                height: min(contentHeight * 0.55, 350)
            )
        default:
            return .zero
        }
    }

    // MARK: - Step Content

    private var stepTitle: String {
        switch currentStep {
        case 0: return L10n.onboardingTourDashboardTitle
        case 1: return L10n.onboardingTourVehicleTitle
        case 2: return L10n.onboardingTourServicesTitle
        case 3: return L10n.onboardingTourCostsTitle
        default: return ""
        }
    }

    private var stepBody: String {
        switch currentStep {
        case 0: return L10n.onboardingTourDashboardBody
        case 1: return L10n.onboardingTourVehicleBody
        case 2: return L10n.onboardingTourServicesBody
        case 3: return L10n.onboardingTourCostsBody
        default: return ""
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        OnboardingTourOverlay(
            appState: AppState(),
            onboardingState: OnboardingState(),
            onSkipTour: {},
            onTourComplete: {}
        )
    }
    .preferredColorScheme(.dark)
}
