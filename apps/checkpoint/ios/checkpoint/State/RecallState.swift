//
//  RecallState.swift
//  checkpoint
//
//  Recall fetch state management
//

import Foundation

struct RecallState {
    enum FetchState {
        case notFetched
        case fetched([RecallInfo])
        case failed
    }

    var fetchStates: [UUID: FetchState] = [:]

    /// Recalls for a specific vehicle
    func recalls(for vehicleID: UUID?) -> [RecallInfo] {
        guard let id = vehicleID,
              case .fetched(let results) = fetchStates[id] else { return [] }
        return results
    }

    /// Whether the recall fetch failed for a specific vehicle
    func fetchFailed(for vehicleID: UUID?) -> Bool {
        guard let id = vehicleID,
              case .failed = fetchStates[id] else { return false }
        return true
    }
}
