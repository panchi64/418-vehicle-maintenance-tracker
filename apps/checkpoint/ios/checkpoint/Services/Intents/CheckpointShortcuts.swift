//
//  CheckpointShortcuts.swift
//  checkpoint
//
//  The App Shortcuts: intents that work by voice the moment the app is
//  installed, with no setup in the Shortcuts app. Apple allows an app up to
//  10 (Human Interface Guidelines, "App Shortcuts"); these are the ten most
//  used, in priority order, so a new one must displace one. Every other
//  intent is still in the Shortcuts app and reachable by Siri through a
//  user-made shortcut (and, on iOS 27 with Apple Intelligence, by Siri AI).
//
//  The in-app Siri tips (`ScreenSiriTip`) show these phrases, and
//  `SiriTipView` shows nothing for an intent that isn't here: keep Check
//  Next Due, Update Mileage, Spending and Find Document.
//
//  Every phrase names the app (`\(.applicationName)`), as App Shortcuts
//  require. Spanish phrases live in `AppShortcuts.xcstrings`, keyed by these
//  English ones.
//

import AppIntents

struct CheckpointShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogServiceIntent(),
            phrases: [
                "Log a service in \(.applicationName)",
                "Log maintenance in \(.applicationName)",
                "Record a service in \(.applicationName)",
                "I got my car serviced in \(.applicationName)"
            ],
            shortTitle: "Log Service",
            systemImageName: "square.and.pencil"
        )

        // "This receipt": Siri takes the one on screen; from the Share Sheet
        // or a shortcut, the file handed over.
        AppShortcut(
            intent: LogReceiptIntent(),
            phrases: [
                "Log this receipt in \(.applicationName)",
                "Log a receipt in \(.applicationName)",
                "Add a receipt to \(.applicationName)"
            ],
            shortTitle: "Log Receipt",
            systemImageName: "doc.text.viewfinder"
        )

        AppShortcut(
            intent: MarkServiceDoneIntent(),
            phrases: [
                "Mark a service done in \(.applicationName)",
                "Mark maintenance done in \(.applicationName)",
                "I finished a service in \(.applicationName)"
            ],
            shortTitle: "Mark Done",
            systemImageName: "checkmark.circle"
        )

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

        // Its snippet lists everything coming up, so it also takes the
        // "coming up" phrases List Upcoming Services had before Find
        // Document took its slot.
        AppShortcut(
            intent: CheckNextDueIntent(),
            phrases: [
                "What's due on my car in \(.applicationName)",
                "Check my car maintenance in \(.applicationName)",
                "What maintenance is due in \(.applicationName)",
                "What's next on my car in \(.applicationName)",
                "What maintenance is coming up in \(.applicationName)",
                "What services are due in \(.applicationName)",
                "Show upcoming maintenance in \(.applicationName)"
            ],
            shortTitle: "Check Next Due",
            systemImageName: "car.fill"
        )

        AppShortcut(
            intent: SpendingSummaryIntent(),
            phrases: [
                "How much have I spent in \(.applicationName)",
                "Show my car spending in \(.applicationName)",
                "What have I spent on my car in \(.applicationName)"
            ],
            shortTitle: "Spending",
            systemImageName: "dollarsign.circle"
        )

        AppShortcut(
            intent: AddServiceIntent(),
            phrases: [
                "Add a service in \(.applicationName)",
                "Add a maintenance reminder in \(.applicationName)",
                "Schedule a service in \(.applicationName)"
            ],
            shortTitle: "Add Service",
            systemImageName: "plus.circle"
        )

        // At a traffic stop or a shop counter: the card, without unlocking
        // into the app. Took List Upcoming Services' slot (Check Next Due's
        // snippet already lists what's coming up); it is also the Documents
        // screen's Siri tip, which needs an App Shortcut to show.
        AppShortcut(
            intent: FindDocumentIntent(),
            phrases: [
                "Show my \(\.$type) in \(.applicationName)",
                "Find my \(\.$type) in \(.applicationName)",
                "Show my car documents in \(.applicationName)",
                "Find a document in \(.applicationName)"
            ],
            shortTitle: "Find Document",
            systemImageName: "doc.text.magnifyingglass"
        )

        AppShortcut(
            intent: LastServiceQueryIntent(),
            phrases: [
                "When did I last service my car in \(.applicationName)",
                "Find my last service in \(.applicationName)",
                "When was my last maintenance in \(.applicationName)"
            ],
            shortTitle: "Last Service",
            systemImageName: "clock.arrow.circlepath"
        )

        AppShortcut(
            intent: GetMileageIntent(),
            phrases: [
                "What's my mileage in \(.applicationName)",
                "Check my mileage in \(.applicationName)",
                "How many miles are on my car in \(.applicationName)"
            ],
            shortTitle: "Get Mileage",
            systemImageName: "gauge.with.dots.needle.67percent"
        )
    }
}
