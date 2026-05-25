import SwiftUI
import DesignKit

struct OnboardingView: View {
    @Environment(\.theme) private var theme
    @Environment(BiomboAppState.self) private var appState
    private let locationService = LocationService.shared

    var body: some View {
        VStack(spacing: DKSpacing.xl) {
            Spacer()

            VStack(alignment: .leading, spacing: DKSpacing.sm) {
                Text("01 // LOCATION")
                    .font(theme.font(.caption, weight: .bold))
                    .foregroundStyle(theme.textTertiary)
                    .tracking(2)

                Text("onboarding.title")
                    .font(theme.font(.largeTitle, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text("onboarding.body")
                    .font(theme.font(.body))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DKSpacing.lg)

            Spacer()

            VStack(spacing: DKSpacing.sm) {
                Button {
                    locationService.requestWhenInUseAuthorization()
                    appState.completeOnboarding()
                } label: {
                    Text("onboarding.allow_location")
                        .font(theme.font(.body, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(theme.backgroundPrimary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(theme.accent)
                }
                .buttonStyle(.plain)

                Button {
                    appState.completeOnboarding()
                } label: {
                    Text("onboarding.skip")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.textSecondary)
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DKSpacing.lg)
            .padding(.bottom, DKSpacing.xl)
        }
        .background(theme.backgroundPrimary.ignoresSafeArea())
    }
}
