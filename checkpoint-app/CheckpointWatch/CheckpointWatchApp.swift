//
//  CheckpointWatchApp.swift
//  CheckpointWatch
//
//  Apple Watch companion app for Checkpoint vehicle maintenance tracker
//  Displays services, allows mileage updates and marking services done
//

import SwiftUI

@main
struct CheckpointWatchApp: App {
    @State private var dataStore = WatchDataStore.shared
    @State private var connectivity = WatchConnectivityService.shared

    init() {
        WatchConnectivityService.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataStore)
                .environment(connectivity)
        }
    }
}
