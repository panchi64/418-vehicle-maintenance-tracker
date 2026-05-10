//
//  Logger+Checkpoint.swift
//  checkpoint
//

import OSLog

extension Logger {
    /// The unified subsystem identifier for Checkpoint app logs.
    /// Use this with `OSLogStore` / Console.app filters to grab everything from the app.
    static let checkpointSubsystem = "com.418-studio.checkpoint"

    /// Convenience init that fills in the Checkpoint subsystem.
    init(category: String) {
        self.init(subsystem: Self.checkpointSubsystem, category: category)
    }
}
