//
//  CheckpointShortcuts.swift
//  checkpoint
//
//  App Shortcuts provider for Siri integration
//  Defines phrases that users can say to invoke intents
//

import AppIntents

/// Provides app shortcuts for Siri voice commands
struct CheckpointShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Check next due service
        AppShortcut(
            intent: CheckNextDueIntent(),
            phrases: [
                "What's due on my car in \(.applicationName)",
                "Check my car maintenance in \(.applicationName)",
                "What maintenance is due in \(.applicationName)",
                "What's next on my car in \(.applicationName)"
            ],
            shortTitle: "Check Next Due",
            systemImageName: "car.fill"
        )

        // List upcoming services
        AppShortcut(
            intent: ListUpcomingServicesIntent(),
            phrases: [
                "What maintenance is coming up in \(.applicationName)",
                "List upcoming services in \(.applicationName)",
                "Show upcoming maintenance in \(.applicationName)",
                "What services are due in \(.applicationName)"
            ],
            shortTitle: "Upcoming Services",
            systemImageName: "list.bullet"
        )

        // Update mileage
        AppShortcut(
            intent: UpdateMileageIntent(),
            phrases: [
                "Update mileage in \(.applicationName)",
                "Log mileage in \(.applicationName)",
                "Update my car mileage in \(.applicationName)",
                "Record mileage in \(.applicationName)"
            ],
            shortTitle: "Update Mileage",
            systemImageName: "speedometer"
        )
    }
}
