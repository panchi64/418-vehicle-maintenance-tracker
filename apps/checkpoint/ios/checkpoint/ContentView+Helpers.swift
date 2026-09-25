//
//  ContentView+Helpers.swift
//  checkpoint
//
//  Helper methods extracted from ContentView
//

import SwiftUI
import SwiftData
import WidgetKit

extension ContentView {
    // MARK: - Lifecycle Handlers

    /// One-time setup on first appearance (once per process launch).
    func performLaunchSetup() {
        // Restore persisted vehicle selection
        restoreSelectedVehicle()
        // If no selection was ever persisted, seed the shared App Group key from
        // the resolved current vehicle so widgets / the Biombo bridge have an ID
        // to read before the first CloudKit remote change.
        seedSharedSelectionIfUnsaved()
        // Only seed sample data for returning users (onboarding completed).
        // New users get sample data seeded when the tour starts.
        if OnboardingState.hasCompletedOnboarding {
            seedSampleDataIfNeeded()
        }
        // Fetch recalls for all existing vehicles
        fetchRecallsForAllVehicles()
        // Analytics: session start
        let serviceCount = (try? modelContext.fetchCount(FetchDescriptor<Service>())) ?? 0
        AnalyticsService.shared.capture(.appSessionStart(
            vehicleCount: vehicles.count,
            serviceCount: serviceCount
        ))
        // Track onboarding start for new users
        if !OnboardingState.hasCompletedOnboarding {
            AnalyticsService.shared.capture(.onboardingStarted)
        }
        // Run the per-activation foreground work for cold launch. The launch
        // `scenePhase == .active` change also fires; whichever runs first wins
        // and the `isForegroundActive` guard makes the other a no-op.
        if scenePhase == .active {
            enterForeground()
        }
    }

    /// Per-activation foreground work. Runs once each time the app becomes
    /// active (cold launch or return from background), never twice for one
    /// activation. Includes `schedulePeriodicNotifications()` so notification
    /// content refreshes on every foreground, not only at cold launch.
    func enterForeground() {
        guard !isForegroundActive else { return }
        isForegroundActive = true

        // Apply odometer readings queued by the Biombo companion app
        applyPendingOdometerUpdates()
        // Update app icon based on service status
        updateAppIcon()
        // Update widget data
        updateWidgetData()
        // Refresh mileage reminders and yearly roundups with the latest data
        schedulePeriodicNotifications()
        // Check for pending Siri mileage update
        handlePendingSiriMileageUpdate()
        // Process pending widget service completions
        processPendingWidgetCompletions()
        // Open a service tapped on the widget (after completions, so a row the
        // widget also marked done opens with its log in place)
        consumePendingWidgetRoute()
        // Analytics
        AnalyticsService.shared.capture(.appOpened)
    }

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            enterForeground()
        case .inactive:
            // Reset on ANY departure from .active — not just a full background
            // transition. A Control Center pull-down, Siri overlay, or system
            // alert resigns the app to .inactive without ever hitting
            // .background; returning to .active must re-run the per-activation
            // work (e.g. draining a PendingMileageUpdate a Siri intent queued
            // while the app was up). A full background transition also passes
            // through .inactive first, so this still covers that case.
            isForegroundActive = false
        case .background:
            updateAppIcon()
            updateWidgetData()
            AnalyticsService.shared.capture(.appBackgrounded)
            AnalyticsService.shared.flush()
        default:
            break
        }
    }

    func handleOnboardingPhaseChange(_ newPhase: OnboardingPhase) {
        switch newPhase {
        case .tour(let step):
            // Each step lives on its tab; switching here mounts the target
            // before the overlay looks for it. Same-tab assigns are no-ops.
            appState.selectedTab = onboardingState.tab(forStep: step)
        case .getStarted:
            // Reached past the last spotlight, so every step was seen.
            AnalyticsService.shared.capture(.onboardingTourCompleted)
            appState.selectedTab = .home
        case .completed:
            AnalyticsService.shared.capture(.onboardingCompleted)
            // Enable CloudKit sync now that onboarding is done
            NotificationCenter.default.post(name: .enableCloudSyncAfterOnboarding, object: nil)
            // No notification request here: the app asks once a service
            // exists, with the reason in front of it (`NotificationAskPolicy`).
        case .intro:
            break
        }
    }

    func handleTabChange(_ newTab: Tab) {
        if let tab = AnalyticsEvent.TabName(rawValue: newTab.rawValue) {
            AnalyticsService.shared.capture(.tabSwitched(tab: tab))
        }
    }

    func handleSelectedVehicleChange(_ newVehicle: Vehicle?) {
        updateAppIcon()
        // Persist selected vehicle ID first so widget reads correct ID
        persistSelectedVehicle(newVehicle)
        updateWidgetData()
        // Analytics
        AnalyticsService.shared.capture(.vehicleSwitched)
    }

    func handleVehiclesChange(from oldVehicles: [Vehicle], to newVehicles: [Vehicle]) {
        // Auto-select first vehicle when none is selected (e.g. iCloud sync after reinstall)
        if appState.selectedVehicle == nil, let first = newVehicles.first {
            appState.selectedVehicle = first
            // Persist eagerly: the selectedVehicle onChange doesn't reliably fire
            // for a mutation made inside this vehicles-onChange, so the shared
            // appSelectedVehicleID key would otherwise stay unset (reinstall +
            // iCloud sync) until the user's first manual switch.
            seedSharedSelectionIfUnsaved()
        }
        // Update selection if current vehicle was deleted
        if let selected = appState.selectedVehicle,
           !newVehicles.contains(where: { $0.id == selected.id }) {
            // Clean up widget data for deleted vehicle
            WidgetDataService.shared.removeWidgetData(for: selected.id.uuidString)
            // Select the previous vehicle in the old list, or fall back to first remaining
            if let oldIndex = oldVehicles.firstIndex(where: { $0.id == selected.id }),
               oldIndex > 0,
               let fallback = newVehicles.first(where: { $0.id == oldVehicles[oldIndex - 1].id }) {
                appState.selectedVehicle = fallback
            } else {
                appState.selectedVehicle = newVehicles.first
            }
        }
        // Update vehicle list when vehicles are added or removed
        if oldVehicles.count != newVehicles.count {
            WidgetDataService.shared.updateVehicleList(newVehicles)
        }
        // Fetch recalls for newly added vehicles
        if newVehicles.count > oldVehicles.count {
            let oldIDs = Set(oldVehicles.map(\.id))
            for vehicle in newVehicles where !oldIDs.contains(vehicle.id) {
                Task {
                    await fetchRecalls(for: vehicle)
                }
            }
        }
    }

    // MARK: - Vehicle Selection Persistence

    /// Restore the previously selected vehicle from UserDefaults
    func restoreSelectedVehicle() {
        // Try to load saved vehicle ID from standard UserDefaults
        guard let savedIDString = UserDefaults.standard.string(forKey: Self.selectedVehicleIDKey),
              let savedID = UUID(uuidString: savedIDString) else {
            // No saved selection, fall back to first vehicle
            if appState.selectedVehicle == nil {
                appState.selectedVehicle = vehicles.first
            }
            return
        }

        // Find the matching vehicle
        if let matchingVehicle = vehicles.first(where: { $0.id == savedID }) {
            appState.selectedVehicle = matchingVehicle
        } else {
            // Saved vehicle no longer exists, fall back to first vehicle
            appState.selectedVehicle = vehicles.first
        }
    }

    /// Persist the selected vehicle ID to both standard and App Group UserDefaults
    func persistSelectedVehicle(_ vehicle: Vehicle?) {
        let vehicleIDString = vehicle?.id.uuidString

        // Save to standard UserDefaults (for app persistence)
        if let idString = vehicleIDString {
            UserDefaults.standard.set(idString, forKey: Self.selectedVehicleIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.selectedVehicleIDKey)
        }

        // Save to shared App Group UserDefaults (for widget access)
        if let sharedDefaults = AppGroupConstants.iPhoneWidgetDefaults() {
            if let idString = vehicleIDString {
                sharedDefaults.set(idString, forKey: Self.selectedVehicleIDKey)
            } else {
                sharedDefaults.removeObject(forKey: Self.selectedVehicleIDKey)
            }
        }
        // Note: Widget reload happens in updateWidgetData() via WidgetDataService
    }

    /// Writes the resolved current vehicle to the shared App Group selection key
    /// when the user has never made an explicit selection (no persisted ID yet).
    ///
    /// The `selectedVehicle` `onChange` is the normal path that persists the
    /// shared `appSelectedVehicleID` key, but it doesn't reliably fire for
    /// selections resolved during launch or set from inside the `vehicles`
    /// `onChange` (reinstall + iCloud sync). Without this eager seed the shared
    /// key would stay unset — leaving widgets and the Biombo bridge without a
    /// vehicle to read — until the user's first manual vehicle switch. Idempotent
    /// and a no-op until a vehicle has resolved.
    func seedSharedSelectionIfUnsaved() {
        guard UserDefaults.standard.string(forKey: Self.selectedVehicleIDKey) == nil,
              let vehicle = currentVehicle else { return }
        persistSelectedVehicle(vehicle)
    }

    // MARK: - Recalls

    /// Fetch recalls for all existing vehicles (called once on app launch)
    func fetchRecallsForAllVehicles() {
        for vehicle in vehicles {
            Task {
                await fetchRecalls(for: vehicle)
            }
        }
    }

    /// Fetch recalls for a vehicle over the network, then hand the result to
    /// `AppState` to store. The network call lives here in the consuming layer
    /// so `AppState` stays a pure state store (it only records the outcome).
    func fetchRecalls(for vehicle: Vehicle) async {
        guard !vehicle.make.isEmpty,
              !vehicle.model.isEmpty,
              vehicle.year > 0 else {
            appState.setRecalls([], for: vehicle.id)
            return
        }

        do {
            let results = try await NHTSAService.shared.fetchRecalls(
                make: vehicle.make,
                model: vehicle.model,
                year: vehicle.year
            )
            appState.setRecalls(results, for: vehicle.id)
            RecallCheckCache.shared.recordSuccess()
        } catch {
            appState.setRecallFetchFailed(for: vehicle.id)
        }
    }

    // MARK: - App Icon

    func updateAppIcon() {
        // The icon only reflects the current vehicle, so hand AppIconService that
        // vehicle's already-materialized `services` relationship instead of
        // fetching (and then re-filtering) the entire Service table on every
        // activation and selection change.
        AppIconService.shared.updateIcon(for: currentVehicle, services: currentVehicle?.services ?? [])
    }

    // MARK: - Widget Data

    func updateWidgetData() {
        // Update vehicle list for widget configuration picker
        WidgetDataService.shared.updateVehicleList(vehicles)

        if let vehicle = currentVehicle {
            WidgetDataService.shared.updateWidget(for: vehicle)
        } else {
            WidgetDataService.shared.clearWidgetData()
        }

        // Publish odometers to the cross-product App Group for Biombo.
        VehicleSharingService.publish(vehicles)
    }

    // MARK: - Companion App (Biombo) Odometer Sync

    /// Apply odometer readings queued by the Biombo companion app, then refresh
    /// derived data so widgets and the shared bridge reflect the new mileage.
    func applyPendingOdometerUpdates() {
        if VehicleSharingService.applyPendingUpdates(in: modelContext) {
            updateAppIcon()
            updateWidgetData()
        }
    }

    // MARK: - Siri Integration

    /// Handle pending mileage update from Siri intent
    func handlePendingSiriMileageUpdate() {
        let pending = PendingMileageUpdate.shared
        guard pending.hasPendingUpdate,
              let vehicleIDString = pending.vehicleID,
              let mileage = pending.mileage else {
            return
        }

        // Clear the pending update immediately to avoid re-processing
        pending.clear()

        // Find the vehicle by ID
        guard let vehicleID = UUID(uuidString: vehicleIDString),
              let vehicle = vehicles.first(where: { $0.id == vehicleID }) else {
            return
        }

        // Select the vehicle if it's not already selected
        if currentVehicle?.id != vehicleID {
            appState.selectVehicle(vehicle)
        }

        // Navigate to home and show mileage update with prefilled value
        appState.selectedTab = .home
        appState.present(.mileageUpdate(prefilled: mileage))
    }

    // MARK: - Widget Completions

    /// Process pending service completions from the widget "Done" button
    func processPendingWidgetCompletions() {
        WidgetDataService.shared.processPendingWidgetCompletions(context: modelContext)
    }

    /// Open the service a widget row tap asked for (`OpenServiceIntent`) by
    /// handing it to the notification-route navigation, which already opens a
    /// single service's detail and ignores vehicles deleted since.
    func consumePendingWidgetRoute() {
        guard let route = PendingWidgetRoute.take() else { return }
        NotificationService.shared.pendingRoute = .services(vehicleID: route.vehicleID, serviceIDs: [route.serviceID])
    }

    // MARK: - Mileage Update

    func updateMileage(_ newMileage: Int, for vehicle: Vehicle) {
        vehicle.recordMileage(newMileage, source: .manual, in: modelContext)

        // Update app icon based on new mileage affecting service status
        updateAppIcon()
        // Update widget data
        updateWidgetData()
        // Reschedule mileage reminder for 14 days from now
        NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: .now)
        // Not a tip-prompt action: an odometer update is upkeep the app asks
        // of the user, not something it did for them (see TipPromptPolicy).
    }

    // MARK: - Periodic Notifications

    func schedulePeriodicNotifications() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date.now)
        let previousYear = currentYear - 1

        // Fetch logs imperatively for the yearly-roundup cost calc rather than
        // holding a root-level @Query that re-renders the body on every write.
        // Group once by vehicle ID so the per-vehicle loop is O(logs), not
        // O(vehicles × logs). (Grouping in memory keeps the SwiftData fetch a
        // simple whole-table read — cleaner than a #Predicate on the optional
        // `vehicle` relationship.)
        let allLogs = (try? modelContext.fetch(FetchDescriptor<ServiceLog>())) ?? []
        let logsByVehicleID = Dictionary(grouping: allLogs) { $0.vehicle?.id }

        for vehicle in vehicles {
            // Schedule mileage reminder if needed
            if let lastUpdate = vehicle.mileageUpdatedAt {
                // Schedule based on last update date
                NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: lastUpdate)
            } else {
                // Never updated - schedule from now
                NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: .now)
            }

            // Calculate previous year's total cost for yearly roundup
            let vehicleLogs = logsByVehicleID[vehicle.id] ?? []
            let previousYearLogs = vehicleLogs.filter {
                calendar.component(.year, from: $0.performedDate) == previousYear
            }
            let previousYearCost = previousYearLogs.honestTotalCost()

            // Schedule yearly roundup if there's data
            NotificationService.shared.scheduleYearlyRoundup(
                for: vehicle,
                previousYearCost: previousYearCost,
                previousYear: previousYear
            )
        }
    }
}
