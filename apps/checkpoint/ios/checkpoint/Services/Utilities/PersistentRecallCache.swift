//
//  PersistentRecallCache.swift
//  checkpoint
//
//  Disk-backed cache for NHTSA recall lookups so users on metered data
//  plans don't re-fetch on every cold launch.
//

import Foundation
import OSLog

private let cacheLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "PersistentRecallCache")

struct PersistentRecallCacheEntry: Codable, Sendable {
    let recalls: [RecallInfo]
    let timestamp: Date
}

enum PersistentRecallCache {
    private static let fileName = "recalls-cache.json"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.iPhoneWidget)?
            .appendingPathComponent(fileName)
    }

    static func read(key: String) -> PersistentRecallCacheEntry? {
        readAll()[key]
    }

    static func write(key: String, recalls: [RecallInfo], timestamp: Date = .now) {
        var store = readAll()
        store[key] = PersistentRecallCacheEntry(recalls: recalls, timestamp: timestamp)
        writeAll(store)
    }

    static func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private static func readAll() -> [String: PersistentRecallCacheEntry] {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path) else { return [:] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String: PersistentRecallCacheEntry].self, from: data)
        } catch {
            cacheLogger.warning("Failed to read recalls cache: \(error.localizedDescription); resetting.")
            try? FileManager.default.removeItem(at: url)
            return [:]
        }
    }

    private static func writeAll(_ store: [String: PersistentRecallCacheEntry]) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(store)
            try data.write(to: url, options: .atomic)
        } catch {
            cacheLogger.error("Failed to write recalls cache: \(error.localizedDescription)")
        }
    }
}
