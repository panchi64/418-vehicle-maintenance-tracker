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
    /// The registered store, for code the system runs outside an intent's
    /// perform flow, where `@Dependency` can't be read — a document entity's
    /// `Transferable` export (`DocumentEntity+Transfer`). The same container,
    /// never a second one.
    private(set) static var container: ModelContainer?

    /// Make `container` the store intents read and write. Called at launch
    /// and again whenever the app swaps its container (onboarding → CloudKit),
    /// so no intent reads the outgoing store. Registering replaces the
    /// previous registration for the type.
    static func register(_ container: ModelContainer) {
        AppDependencyManager.shared.add(dependency: container)
        self.container = container
    }
}
