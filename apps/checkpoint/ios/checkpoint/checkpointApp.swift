//
//  checkpointApp.swift
//  checkpoint
//
//  Created by Francisco Casiano on 1/20/26.
//

import SwiftUI
import SwiftData
import StoreKit
import UserNotifications
import WatchConnectivity
import os

private let appLogger = Logger(category: "App")

@main
struct checkpointApp: App {

    // CloudKit container identifier for iCloud sync
    private static let cloudKitContainerID = "iCloud.com.418-studio.checkpoint"

    @State private var modelContainer: ModelContainer

    /// Create a ModelContainer with or without CloudKit sync.
    /// During onboarding, sync is deferred to prevent iCloud data from interfering
    /// with the sample-data tour. Once onboarding completes, a notification triggers
    /// re-creation with CloudKit enabled.
    static func createContainer(syncEnabled: Bool) -> ModelContainer {
        // Built from the versioned schema so schema changes ship as staged
        // migrations via CheckpointMigrationPlan rather than implicit
        // lightweight migration. See CheckpointSchema.swift.
        let schema = Schema(versionedSchema: CheckpointSchemaV1.self)

        let storeURL = AppGroupConstants.iPhoneWidgetContainerURL?.appendingPathComponent("checkpoint.store")

        if syncEnabled {
            // Try CloudKit-enabled configuration first
            do {
                let cloudConfig: ModelConfiguration
                if let storeURL = storeURL {
                    cloudConfig = ModelConfiguration(
                        schema: schema,
                        url: storeURL,
                        cloudKitDatabase: .private(cloudKitContainerID)
                    )
                } else {
                    cloudConfig = ModelConfiguration(
                        schema: schema,
                        cloudKitDatabase: .private(cloudKitContainerID)
                    )
                }
                return try ModelContainer(
                    for: schema,
                    migrationPlan: CheckpointMigrationPlan.self,
                    configurations: [cloudConfig]
                )
            } catch {
                // CloudKit failed - fall back to local storage
                appLogger.error("CloudKit initialization failed: \(error.localizedDescription). Falling back to local storage.")
            }
        }

        // Local-only configuration (either by user preference or CloudKit failure)
        let localConfig: ModelConfiguration
        if let storeURL = storeURL {
            localConfig = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            // Fallback to default location
            localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: CheckpointMigrationPlan.self,
                configurations: [localConfig]
            )
        } catch {
            appLogger.fault("Could not create ModelContainer: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    init() {
        // Register UserDefaults defaults
        DistanceSettings.registerDefaults()
        AppIconSettings.registerDefaults()
        SyncSettings.registerDefaults()
        AnalyticsSettings.registerDefaults()
        PurchaseSettings.registerDefaults()
        ThemeManager.registerDefaults()
        PurchaseSettings.shared.hasShownTipModalThisSession = false

        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationService.shared

        // Initialize analytics
        AnalyticsService.shared.initialize()

        // Determine whether to enable CloudKit sync at launch.
        // Defer sync during onboarding so iCloud data doesn't interfere with the tour.
        let hasCompleted = OnboardingState.hasCompletedOnboarding
        let userSyncPref = SyncSettings.shared.iCloudSyncEnabled
        let syncEnabled = hasCompleted && userSyncPref
        let container = Self.createContainer(syncEnabled: syncEnabled)
        _modelContainer = State(initialValue: container)

        // Run post-launch backfills off the blocking launch path: dispatch as
        // a main-actor task so the table scans happen after first render rather
        // than delaying it. Each backfill is idempotent (gated by its own
        // UserDefaults flag, or cheap and safe to repeat), so this stays correct
        // on every launch.
        Task { @MainActor in
            ServiceMigrationService.runPostLaunchBackfills(in: container.mainContext)
        }

        // Initialize Watch connectivity
        WatchSessionService.shared.modelContainer = container
        WatchSessionService.shared.activate()

        // Widget snapshots re-serialize from this container on remote CloudKit changes
        WidgetDataService.shared.modelContainer = container
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme({
                    switch ThemeManager.shared.current.colorScheme {
                    case .dark: return .dark
                    case .light: return .light
                    case .system: return nil
                    }
                }())
                .task {
                    // Only request notification permission after onboarding is completed
                    // This avoids overwhelming new users with system prompts during intro
                    if OnboardingState.hasCompletedOnboarding {
                        await NotificationService.shared.checkAuthorizationStatus()
                        if !NotificationService.shared.isAuthorized {
                            let granted = await NotificationService.shared.requestAuthorization()
                            if granted {
                                AnalyticsService.shared.capture(.notificationPermissionGranted)
                            } else {
                                AnalyticsService.shared.capture(.notificationPermissionDenied)
                            }
                        }

                        // Sweep orphaned service notifications and refresh pending
                        // content (vehicle renames, pace changes). Skipped when the
                        // fetch fails so a transient error can't wipe valid reminders.
                        if let vehicles = try? modelContainer.mainContext.fetch(FetchDescriptor<Vehicle>()) {
                            await ServiceNotificationScheduler.performLaunchMaintenance(for: vehicles)
                        }
                    }

                    // Check iCloud account status
                    await SyncStatusService.shared.checkAccountStatus()

                    // During onboarding, check if user has existing data in iCloud
                    if !OnboardingState.hasCompletedOnboarding {
                        await SyncStatusService.shared.checkForExistingCloudData()
                    }

                    // Load StoreKit products
                    await StoreManager.shared.loadProducts()
                }
                .onReceive(NotificationCenter.default.publisher(for: .enableCloudSyncAfterOnboarding)) { _ in
                    let userSyncPref = SyncSettings.shared.iCloudSyncEnabled
                    guard userSyncPref else { return }
                    appLogger.info("Onboarding complete — enabling CloudKit sync")
                    let newContainer = Self.createContainer(syncEnabled: true)
                    modelContainer = newContainer
                    WatchSessionService.shared.modelContainer = newContainer
                    WidgetDataService.shared.modelContainer = newContainer
                }
        }
        .modelContainer(modelContainer)
    }
}
