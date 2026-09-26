//
//  IntentDependencies.swift
//  checkpoint
//
//  The one data path for App Intents: the app's own `ModelContainer`,
//  registered with `AppDependencyManager` and read back with
//  `@Dependency var container: ModelContainer` in intents and entity queries.
//
//  Intents run in the app process, so they share the store the UI writes —
//  no App Group snapshot to go stale. The widget and Control extensions run
//  out of process and keep reading snapshots instead.
//

import AppIntents
import SwiftData

enum IntentDependencies {
    /// Make `container` the store intents read and write. Called at launch
    /// and again whenever the app swaps its container (onboarding → CloudKit),
    /// so no intent reads the outgoing store. Registering replaces the
    /// previous registration for the type.
    static func register(_ container: ModelContainer) {
        AppDependencyManager.shared.add(dependency: container)
    }
}
