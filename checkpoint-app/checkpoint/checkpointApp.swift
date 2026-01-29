//
//  checkpointApp.swift
//  checkpoint
//
//  Created by Francisco Casiano on 1/20/26.
//

import SwiftUI
import SwiftData
import UserNotifications

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

        let modelConfiguration: ModelConfiguration

        // Check if user has iCloud sync enabled
        // Note: We read directly from UserDefaults here since SyncSettings
        // may not be initialized yet during static property initialization
        let syncEnabled = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true

        if syncEnabled {
            // CloudKit-enabled configuration (syncs via user's iCloud account)
            // Note: CloudKit configuration cannot use custom URL, so we use default location
            modelConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .automatic
            )
        } else {
            // Local-only configuration using App Group for widget access
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
                let storeURL = containerURL.appendingPathComponent("checkpoint.store")
                modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            } else {
                // Fallback to default location
                modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            }
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Register UserDefaults defaults
        DistanceSettings.registerDefaults()
        AppIconSettings.registerDefaults()
        SyncSettings.registerDefaults()

        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task {
                    // Request notification authorization on app launch
                    await NotificationService.shared.checkAuthorizationStatus()
                    if !NotificationService.shared.isAuthorized {
                        _ = await NotificationService.shared.requestAuthorization()
                    }

                    // Check iCloud account status
                    await SyncStatusService.shared.checkAccountStatus()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
