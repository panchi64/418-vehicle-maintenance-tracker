//
//  PersistentRecallCache.swift
//  checkpoint
//
//  Disk-backed cache for NHTSA recall lookups across launches.
//

import Foundation
import OSLog

private let cacheLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "PersistentRecallCache")

actor PersistentRecallCache {
    static let shared = PersistentRecallCache()

    private static let fileName = "recalls-cache.json"

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
        store = current
        flush(current)
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
            store = decoded
            return decoded
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
