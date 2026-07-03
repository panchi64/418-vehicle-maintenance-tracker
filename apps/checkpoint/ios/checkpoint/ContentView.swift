//
//  ContentView.swift
//  checkpoint
//
//  Root TabView container with persistent vehicle header and FAB
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Query var vehicles: [Vehicle]

    @State var appState = AppState()
    @State var onboardingState = OnboardingState()
    @State var delayedTask: Task<Void, Never>?

    /// Guards the per-activation foreground work so it runs once each time the
    /// app becomes active (cold launch or return from background) rather than
    /// twice — `onAppear` and the launch `scenePhase == .active` both fire at
    /// cold launch. Reset on background so the next foreground re-runs it.
    @State var isForegroundActive = false

    // MARK: - Vehicle Selection Persistence

    static let selectedVehicleIDKey = AppGroupConstants.appSelectedVehicleIDKey

    var currentVehicle: Vehicle? {
        appState.selectedVehicle ?? vehicles.first
    }

    var showOnboardingIntro: Bool {
        onboardingState.currentPhase == .intro
    }

    // MARK: - Body

    var body: some View {
        notificationHandlers(
            onboardingSurfaces(
                centralizedSheets(
                    rootLayout
                        .onAppear { performLaunchSetup() }
                        .onChange(of: onboardingState.currentPhase) { _, newPhase in
                            handleOnboardingPhaseChange(newPhase)
                        }
                        .onChange(of: appState.selectedTab) { _, newTab in
                            handleTabChange(newTab)
                        }
                        .onChange(of: scenePhase) { _, newPhase in
                            handleScenePhaseChange(newPhase)
                        }
                        .onChange(of: appState.selectedVehicle) { _, newVehicle in
                            handleSelectedVehicleChange(newVehicle)
                        }
                        .onChange(of: vehicles) { oldVehicles, newVehicles in
                            handleVehiclesChange(from: oldVehicles, to: newVehicles)
                        }
                )
            )
        )
    }

    // MARK: - Root Layout

    /// The persistent visual shell: atmospheric background, vehicle header,
    /// swipeable tab content, bottom fade, floating tab bar, and toast overlay.
    private var rootLayout: some View {
        ZStack {
            AtmosphericBackground()

            VStack(spacing: 0) {
                // Persistent vehicle header
                VehicleHeader(
                    vehicle: currentVehicle,
                    onTap: { appState.showVehiclePicker = true },
                    onMileageTap: { appState.showMileageUpdate = true },
                    onSettingsTap: { appState.showSettings = true }
                )
                .tourTarget(.vehicleHeader, active: onboardingState.currentPhase.isTour)
                .padding(.top, Spacing.sm)
                .revealAnimation(delay: 0.1)

                tabContent
            }

            bottomFade
        }
        // Tab bar overlay - floats over content with glass effect
        .overlay(alignment: .bottom) {
            BrutalistTabBar(
                selectedTab: $appState.selectedTab,
                onLogTapped: currentVehicle != nil ? {
                    appState.addServiceMode = .record
                    appState.showAddService = true
                } : nil,
                onScheduleTapped: currentVehicle != nil ? {
                    appState.addServiceMode = .remind
                    appState.showAddService = true
                } : nil
            )
            .revealAnimation(delay: 0.3)
        }
        .overlay(alignment: .bottom) {
            if let toast = ToastService.shared.currentToast {
                ToastView(toast: toast)
                    .transition(.opacity)
                    .padding(.bottom, 72 + Spacing.lg)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .animation(.easeOut(duration: Theme.animationMedium), value: ToastService.shared.currentToast?.id)
            }
        }
    }

    /// Swipeable tab switch. Tabs read `appState` from the environment and take
    /// the selected vehicle so each scopes its SwiftData queries to that vehicle.
    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch appState.selectedTab {
            case .home:
                HomeTab(vehicle: appState.selectedVehicle, onboardingState: onboardingState)
            case .services:
                ServicesTab(vehicle: appState.selectedVehicle, onboardingState: onboardingState)
            case .costs:
                CostsTab(vehicle: appState.selectedVehicle, onboardingState: onboardingState)
            }
        }
        .environment(appState)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .simultaneousGesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // Tab swipes are disabled while any onboarding surface is up —
                    // the tour overlay's tap blocker only catches taps, so without
                    // this guard a horizontal drag would desync the spotlighted
                    // anchor from the visible tab.
                    guard !onboardingState.currentPhase.isActiveOnboarding else { return }

                    let horizontalSwipe = value.translation.width
                    let verticalSwipe = abs(value.translation.height)

                    // Only trigger if horizontal movement dominates
                    guard abs(horizontalSwipe) > verticalSwipe else { return }

                    // Soft haptic feedback for tab switch
                    HapticService.shared.tabChanged()

                    withAnimation(.easeOut(duration: Theme.animationMedium)) {
                        if horizontalSwipe > 0 {
                            // Swipe right -> go to previous tab
                            appState.selectedTab = appState.selectedTab.previous
                        } else {
                            // Swipe left -> go to next tab
                            appState.selectedTab = appState.selectedTab.next
                        }
                    }
                }
        )
        // Reserve space at bottom for floating tab bar
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 72)
        }
    }

    /// Subtle bottom fade so content peeks through the glass tab bar.
    private var bottomFade: some View {
        VStack(spacing: 0) {
            Spacer()
            LinearGradient(
                colors: [
                    Theme.backgroundPrimary.opacity(0),
                    Theme.backgroundPrimary.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            Theme.backgroundPrimary.opacity(0.7)
                .frame(height: 34)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self], inMemory: true)
        .preferredColorScheme(.dark)
}
