//
//  ServiceFormDraftStore.swift
//  checkpoint
//
//  Persists a ServiceFormDraft in UserDefaults, one per form subject: a new
//  entry per vehicle, a completion per service, an edit per log. Drafts older
//  than 7 days are treated as abandoned and cleared on read (F10).
//

import Foundation

enum ServiceFormDraftStore {
    /// Which form a draft belongs to. A Mark Done draft for one service must
    /// never resurface in [+], or in another service's completion.
    enum Scope: Equatable {
        case newEntry(vehicleID: UUID)
        case completion(serviceID: UUID)
        case edit(logID: UUID)

        var storageKey: String {
            switch self {
            // Unchanged from before scopes existed, so a stored draft survives.
            case .newEntry(let id): return "serviceFormDraft.\(id.uuidString)"
            case .completion(let id): return "serviceFormDraft.complete.\(id.uuidString)"
            case .edit(let id): return "serviceFormDraft.edit.\(id.uuidString)"
            }
        }
    }

    private static let maxAge: TimeInterval = 7 * 24 * 60 * 60

    /// Returns the stored draft, or nil if absent, corrupt, or older than 7 days
    /// (an expired draft is cleared as a side effect of this read).
    static func load(_ scope: Scope) -> ServiceFormDraft? {
        let storageKey = scope.storageKey
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        guard let draft = try? JSONDecoder().decode(ServiceFormDraft.self, from: data),
              draft.version == ServiceFormDraft.currentVersion else {
            // Either the payload predates the current schema or it decoded but
            // means something different. Both are discarded rather than
            // partially applied — a wrong draft is worse than none.
            UserDefaults.standard.removeObject(forKey: storageKey)
            return nil
        }
        guard Date.now.timeIntervalSince(draft.savedAt) <= maxAge else {
            UserDefaults.standard.removeObject(forKey: storageKey)
            return nil
        }
        return draft
    }

    static func save(_ draft: ServiceFormDraft, _ scope: Scope) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: scope.storageKey)
    }

    static func clear(_ scope: Scope) {
        UserDefaults.standard.removeObject(forKey: scope.storageKey)
    }

    // MARK: - New-entry shorthands

    static func load(for vehicleID: UUID) -> ServiceFormDraft? {
        load(.newEntry(vehicleID: vehicleID))
    }

    static func save(_ draft: ServiceFormDraft, for vehicleID: UUID) {
        save(draft, .newEntry(vehicleID: vehicleID))
    }

    static func clear(for vehicleID: UUID) {
        clear(.newEntry(vehicleID: vehicleID))
    }
}
