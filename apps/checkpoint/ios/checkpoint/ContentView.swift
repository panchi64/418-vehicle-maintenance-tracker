//
//  ContentView.swift
//  checkpoint
//
//  Root shell: the system TabView, one NavigationStack per tab
//  (`TabRootStack`), the single root sheet router, and the onboarding surfaces.
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
    @State var tourSpotlights = TourSpotlightRegistry()
    @State var delayedTask: Task<Void, Never>?

    /// Guards the per-activation foreground work so it runs once each time the
    /// app becomes active (cold launch or return from background/interruption)
    /// rather than twice — `onAppear` and the launch `scenePhase == .active`
    /// both fire at cold launch. Reset on any departure from `.active`
    /// (`.inactive`, which precedes `.background`) so the next return to
    /// `.active` re-runs it.
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
                sheetRouter(
                    tabs
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
        .environment(appState)
        .environment(tourSpotlights)
        // Toasts render in their own window above sheets (`ToastWindow`).
        .background { ToastWindowInstaller() }
    }

    // MARK: - Tabs

    /// Tabs read `appState` from the environment and take the selected vehicle
    /// so each scopes its SwiftData queries to that vehicle.
    private var tabs: some View {
        TabView(selection: $appState.selectedTab) {
            SwiftUI.Tab(Tab.home.title, systemImage: Tab.home.icon, value: Tab.home) {
                TabRootStack(tab: .home, vehicles: vehicles) {
                    HomeTab(vehicle: appState.selectedVehicle, onboardingState: onboardingState)
                }
            }
            SwiftUI.Tab(Tab.services.title, systemImage: Tab.services.icon, value: Tab.services) {
                TabRootStack(tab: .services, vehicles: vehicles) {
                    ServicesTab(vehicle: appState.selectedVehicle, onboardingState: onboardingState)
                }
            }
            SwiftUI.Tab(Tab.costs.title, systemImage: Tab.costs.icon, value: Tab.costs) {
                TabRootStack(tab: .costs, vehicles: vehicles) {
                    CostsTab(vehicle: appState.selectedVehicle, onboardingState: onboardingState)
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self], inMemory: true)
        .preferredColorScheme(.dark)
}
