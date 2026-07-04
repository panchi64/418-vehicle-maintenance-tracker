//
//  PersistentRecallCache.swift
//  checkpoint
//
//  Disk-backed cache for NHTSA recall lookups across launches.
//

import Foundation
import OSLog

private nonisolated let cacheLogger = Logger(category: "PersistentRecallCache")

actor PersistentRecallCache {
    static let shared = PersistentRecallCache()

    private static let fileName = "recalls-cache.json"

    // Retention is deliberately far longer than the 1-hour recalls TTL: NHTSAService
    // reads this cache as an *offline fallback*, returning stale data when the network
    // is unavailable. Pruning here only bounds unbounded file growth, so entries live
    // for a generous window and the cache is capped to the newest N vehicles.
    private nonisolated static let maxEntryAge: TimeInterval = 30 * 24 * 60 * 60  // 30 days
    private nonisolated static let maxEntries = 100

    private var store: [String: CacheEntry<[RecallInfo]>]?

    private var fileURL: URL? {
        AppGroupConstants.iPhoneWidgetContainerURL?.appendingPathComponent(Self.fileName)
    }

    func read(key: String) -> CacheEntry<[RecallInfo]>? {
        loadIfNeeded()[key]
    }

    func write(key: String, recalls: [RecallInfo], timestamp: Date = .now) {
        var current = loadIfNeeded()
        current[key] = CacheEntry(data: recalls, timestamp: timestamp)
        let bounded = Self.prune(current)
        store = bounded
        flush(bounded)
    }

    func clear() {
        store = [:]
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func loadIfNeeded() -> [String: CacheEntry<[RecallInfo]>] {
        if let store { return store }
        guard let url = fileURL else {
            store = [:]
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: CacheEntry<[RecallInfo]>].self, from: data)
            let bounded = Self.prune(decoded)
            store = bounded
            // Rewrite only when pruning actually dropped something, so a stale file
            // shrinks on next launch instead of growing without bound.
            if bounded.count != decoded.count {
                flush(bounded)
            }
            return bounded
        } catch CocoaError.fileReadNoSuchFile {
            store = [:]
            return [:]
        } catch {
            cacheLogger.warning("Recalls cache unreadable, resetting: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: url)
            store = [:]
            return [:]
        }
    }

    /// Drops entries older than `maxEntryAge` and, if still over `maxEntries`,
    /// keeps only the most recently written ones.
    private nonisolated static func prune(
        _ store: [String: CacheEntry<[RecallInfo]>],
        now: Date = .now
    ) -> [String: CacheEntry<[RecallInfo]>] {
        CacheEntry.prune(store, maxEntries: maxEntries) {
            now.timeIntervalSince($0.timestamp) < maxEntryAge
        }
    }

    private func flush(_ snapshot: [String: CacheEntry<[RecallInfo]>]) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
        } catch {
            cacheLogger.error("Failed to write recalls cache: \(error.localizedDescription)")
        }
    }
}
