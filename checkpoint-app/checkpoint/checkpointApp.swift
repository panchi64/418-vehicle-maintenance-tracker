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
    private static let appGroupID = "group.com.checkpoint.shared"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Vehicle.self,
            Service.self,
            ServiceLog.self,
            ServicePreset.self,
        ])

        // Use App Group container for shared access with widget
        let modelConfiguration: ModelConfiguration
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = containerURL.appendingPathComponent("checkpoint.store")
            modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            // Fallback to default location if app group is not available
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
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
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
