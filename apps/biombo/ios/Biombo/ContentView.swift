import SwiftUI
import DesignKit

struct ContentView: View {
    @Environment(BiomboAppState.self) private var appState
    @Environment(OdometerStore.self) private var odometerStore
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            OfflineBannerSlot()

            header
                .padding(.horizontal, DKSpacing.md)
                .padding(.top, DKSpacing.md)
                .padding(.bottom, DKSpacing.sm)

            if odometerStore.hasVehicles {
                OdometerCard()
                    .padding(.horizontal, DKSpacing.md)
                    .padding(.bottom, DKSpacing.sm)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(theme.backgroundPrimary.ignoresSafeArea())
        .sheet(isPresented: $state.showingSettings) { FuelSettingsView() }
        .sheet(isPresented: $state.showingSubmitSheet) { SubmitPriceSheet() }
        .fullScreenCover(isPresented: .constant(!appState.hasCompletedOnboarding)) {
            OnboardingView()
        }
    }

    private var header: some View {
        HStack(spacing: DKSpacing.sm) {
            Text("BIOMBO")
                .font(theme.font(.headline, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .tracking(4)
                .accessibilityIdentifier("app.title")

            Spacer()

            viewModePicker

            Button {
                appState.showingSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("action.open-settings")
            .buttonStyle(.plain)
        }
    }

    private var viewModePicker: some View {
        HStack(spacing: 0) {
            ForEach(BiomboViewMode.allCases) { mode in
                Button {
                    appState.viewMode = mode
                } label: {
                    Text(mode.label)
                        .font(theme.font(.caption, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(
                            appState.viewMode == mode ? theme.backgroundPrimary : theme.textPrimary
                        )
                        .frame(minWidth: 64, minHeight: 36)
                        .background(appState.viewMode == mode ? theme.accent : .clear)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("viewMode.\(mode.rawValue)")
            }
        }
        .brutalistBorder(color: theme.borderSubtle, lineWidth: 2)
    }

    @ViewBuilder
    private var content: some View {
        switch appState.viewMode {
        case .map: FuelMapView()
        case .list: FuelListView()
        }
    }
}

#Preview {
    ContentView()
        .environment(BiomboAppState())
        .environment(OdometerStore())
}
