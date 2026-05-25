//
//  RecallCheckCache.swift
//  checkpoint
//
//  Caches the timestamp of the last successful recall check
//

import Foundation

@MainActor
final class RecallCheckCache {
    static let shared = RecallCheckCache()

    private let key = "lastRecallCheckDate"

    private init() {}

    /// Record a successful recall check
    func recordSuccess() {
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: key)
    }

    /// The last successful check date, if any
    var lastCheckedDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: key)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Human-readable description of when the last check occurred
    var lastCheckedDescription: String? {
        guard let date = lastCheckedDate else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
