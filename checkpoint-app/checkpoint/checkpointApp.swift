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

private let appLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "App")

@main
struct checkpointApp: App {

    // App Group identifier for sharing data with widget
    private static let appGroupID = "group.com.418-studio.checkpoint.shared"

    // CloudKit container identifier for iCloud sync
    private static let cloudKitContainerID = "iCloud.com.418-studio.checkpoint"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Vehicle.self,
            Service.self,
            ServiceLog.self,
            ServicePreset.self,
            MileageSnapshot.self,
            ServiceAttachment.self,
        ])

        // Check if user has iCloud sync enabled
        // Note: We read directly from UserDefaults here since SyncSettings
        // may not be initialized yet during static property initialization
        let syncEnabled = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true

        // Use App Group container for shared access with widget
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        let storeURL = containerURL?.appendingPathComponent("checkpoint.store")

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
                return try ModelContainer(for: schema, configurations: [cloudConfig])
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
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            appLogger.fault("Could not create ModelContainer: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

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

        // Initialize CloudSyncStatusService to start monitoring
        _ = CloudSyncStatusService.shared

        // Initialize analytics
        AnalyticsService.shared.initialize()

        // Initialize Watch connectivity
        WatchSessionService.shared.modelContainer = sharedModelContainer
        WatchSessionService.shared.activate()
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
                    }

                    // Check iCloud account status
                    await SyncStatusService.shared.checkAccountStatus()

                    // Load StoreKit products
                    await StoreManager.shared.loadProducts()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
