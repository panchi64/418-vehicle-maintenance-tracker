//
//  ServiceFormDraftStore.swift
//  checkpoint
//
//  Persists a ServiceFormDraft per vehicle in UserDefaults. Drafts older than
//  7 days are treated as abandoned and cleared on read (F10).
//

import Foundation

enum ServiceFormDraftStore {
    private static let maxAge: TimeInterval = 7 * 24 * 60 * 60

    private static func key(for vehicleID: UUID) -> String {
        "serviceFormDraft.\(vehicleID.uuidString)"
    }

    /// Returns the stored draft, or nil if absent, corrupt, or older than 7 days
    /// (an expired draft is cleared as a side effect of this read).
    static func load(for vehicleID: UUID) -> ServiceFormDraft? {
        let storageKey = key(for: vehicleID)
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        guard let draft = try? JSONDecoder().decode(ServiceFormDraft.self, from: data),
              draft.version == ServiceFormDraft.currentVersion else {
            // Either the payload predates the current schema (decode fails on
            // the non-optional `version`) or it decoded but means something
            // different. Both are discarded rather than partially applied — a
            // draft is a convenience, and a wrong one is worse than none.
            UserDefaults.standard.removeObject(forKey: storageKey)
            return nil
        }
        guard Date.now.timeIntervalSince(draft.savedAt) <= maxAge else {
            UserDefaults.standard.removeObject(forKey: storageKey)
            return nil
        }
        return draft
    }

    static func save(_ draft: ServiceFormDraft, for vehicleID: UUID) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: key(for: vehicleID))
    }

    static func clear(for vehicleID: UUID) {
        UserDefaults.standard.removeObject(forKey: key(for: vehicleID))
    }
}
