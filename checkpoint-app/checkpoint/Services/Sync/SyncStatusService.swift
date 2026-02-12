//
//  SyncStatusService.swift
//  checkpoint
//
//  Service for tracking iCloud sync status and errors
//

import Foundation
import CloudKit

/// Represents the current state of iCloud sync
enum SyncState: Equatable {
    case idle
    case syncing
    case synced
    case error(String)
    case disabled
    case noAccount

    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .synced:
            return "Synced"
        case .error(let message):
            return message
        case .disabled:
            return "Sync disabled"
        case .noAccount:
            return "Sign in to iCloud"
        }
    }

    var isError: Bool {
        if case .error = self { return true }
        if case .noAccount = self { return true }
        return false
    }
}

/// Service for monitoring and reporting iCloud sync status
@Observable
@MainActor
final class SyncStatusService {
    static let shared = SyncStatusService()

    // MARK: - Observable State

    /// Current sync state
    private(set) var syncState: SyncState = .idle

    /// Last successful sync date
    private(set) var lastSyncDate: Date?

    /// Whether the user has an iCloud account available
    private(set) var hasICloudAccount: Bool = false

    /// Whether existing Checkpoint data was found in iCloud (from a previous install)
    private(set) var hasExistingCloudData: Bool = false

    // MARK: - Computed Properties

    /// Human-readable last sync description
    var lastSyncDescription: String? {
        guard let date = lastSyncDate else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Whether sync is currently enabled in settings
    var isSyncEnabled: Bool {
        SyncSettings.shared.iCloudSyncEnabled
    }

    private init() {
        // Load persisted last sync date
        lastSyncDate = SyncSettings.shared.lastSyncDate

        // Check initial account status
        Task {
            await checkAccountStatus()
        }
    }

    // MARK: - Account Status

    /// Check if user has an iCloud account
    func checkAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            hasICloudAccount = (status == .available)

            if !hasICloudAccount && isSyncEnabled {
                syncState = .noAccount
            } else if !isSyncEnabled {
                syncState = .disabled
            } else {
                syncState = .idle
            }
        } catch {
            hasICloudAccount = false
            if isSyncEnabled {
                syncState = .error("Unable to check iCloud status")
            }
        }
    }

    // MARK: - Cloud Data Check

    /// Query CloudKit to see if the user has existing Checkpoint vehicle data
    /// (e.g. from a previous install). Only meaningful during onboarding.
    func checkForExistingCloudData() async {
        guard hasICloudAccount else {
            hasExistingCloudData = false
            return
        }

        do {
            let container = CKContainer(identifier: "iCloud.com.418-studio.checkpoint")
            let database = container.privateCloudDatabase

            // CoreData+CloudKit stores in this zone with CD_ prefix on record types
            let zoneID = CKRecordZone.ID(
                zoneName: "com.apple.coredata.cloudkit.zone",
                ownerName: CKCurrentUserDefaultName
            )
            let query = CKQuery(recordType: "CD_Vehicle", predicate: NSPredicate(value: true))
            let (matchResults, _) = try await database.records(
                matching: query,
                inZoneWith: zoneID,
                desiredKeys: [],
                resultsLimit: 1
            )
            hasExistingCloudData = !matchResults.isEmpty
        } catch {
            // Network error or zone doesn't exist — no data to offer
            hasExistingCloudData = false
        }
    }

    // MARK: - Sync Status Updates

    /// Called when remote changes are received from CloudKit
    func didReceiveRemoteChanges() {
        lastSyncDate = Date()
        SyncSettings.shared.lastSyncDate = lastSyncDate
        syncState = .synced

        // Reset to idle after a short delay
        Task {
            try? await Task.sleep(for: .seconds(2))
            if syncState == .synced {
                syncState = .idle
            }
        }
    }

    /// Called when a sync operation starts
    func didStartSync() {
        guard isSyncEnabled else {
            syncState = .disabled
            return
        }
        syncState = .syncing
    }

    /// Called when a sync operation completes successfully
    func didCompleteSync() {
        lastSyncDate = Date()
        SyncSettings.shared.lastSyncDate = lastSyncDate
        syncState = .synced

        // Reset to idle after a short delay
        Task {
            try? await Task.sleep(for: .seconds(2))
            if syncState == .synced {
                syncState = .idle
            }
        }
    }

    /// Called when a sync operation fails
    func didFailSync(with error: Error) {
        let message = humanReadableError(from: error)
        syncState = .error(message)
    }

    /// Update state when sync is toggled
    func syncSettingChanged(enabled: Bool) {
        if enabled {
            Task {
                await checkAccountStatus()
            }
        } else {
            syncState = .disabled
        }
    }

    // MARK: - Error Handling

    /// Convert CloudKit errors to user-friendly messages
    private func humanReadableError(from error: Error) -> String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return "No internet connection"
            case .quotaExceeded:
                return "iCloud storage full"
            case .notAuthenticated:
                return "Sign in to iCloud"
            case .serverResponseLost:
                return "Connection interrupted"
            case .serviceUnavailable:
                return "iCloud unavailable"
            case .zoneBusy:
                return "Server busy, try later"
            default:
                return "Sync error"
            }
        }
        return "Sync error"
    }
}
