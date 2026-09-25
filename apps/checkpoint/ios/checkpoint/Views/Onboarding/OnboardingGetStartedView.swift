//
//  OnboardingGetStartedView.swift
//  checkpoint
//
//  The hand-off after the tour: add your vehicle, bring back iCloud
//  vehicles, or skip.
//
//  This used to be a second VIN form (field, camera, lookup, marbete) that
//  handed its answers to Add Vehicle — which asks for the VIN first and now
//  decodes it by itself. Asking twice is the "Ask once" defect, so the page
//  is one decision and Add Vehicle does the work.
//

import SwiftUI

struct OnboardingGetStartedView: View {
    let onAddVehicle: () -> Void
    let onUseICloudVehicles: () -> Void
    let onSkip: () -> Void

    private var offersICloud: Bool {
        SyncStatusService.shared.hasICloudAccount && SyncStatusService.shared.hasExistingCloudData
    }

    var body: some View {
        ZStack {
            AtmosphericBackground()

            VStack(alignment: .leading, spacing: Spacing.lg) {
                Spacer()

                Text(L10n.onboardingGetStartedTitle)
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)

                Text(L10n.onboardingGetStartedBody)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button(action: onAddVehicle) {
                    Text(L10n.onboardingGetStartedAddVehicle)
                }
                .buttonStyle(.primary)

                // Only when iCloud actually holds this app's data.
                if offersICloud {
                    VStack(spacing: Spacing.sm) {
                        Button(action: onUseICloudVehicles) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "icloud.fill")
                                    .font(.body.weight(.medium))
                                    .accessibilityHidden(true)
                                Text(L10n.onboardingGetStartedUseICloud)
                            }
                        }
                        .buttonStyle(.secondary)

                        Text(L10n.onboardingGetStartedICloudHelp)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Button(action: onSkip) {
                    Text(L10n.onboardingGetStartedSkip)
                        .brutalistLabelStyle(color: Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .minimumTouchTarget()
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
            .scrollingWhenTooTall()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    OnboardingGetStartedView(onAddVehicle: {}, onUseICloudVehicles: {}, onSkip: {})
}
