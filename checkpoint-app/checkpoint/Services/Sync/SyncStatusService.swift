//
//  SyncStatusService.swift
//  checkpoint
//
//  Consolidated service for tracking iCloud sync status, network monitoring,
//  and remote change observation.
//

import Foundation
import SwiftUI
import CloudKit
import CoreData
import Network
import Combine

/// Represents a sync error with user-facing messaging and UI properties
enum SyncError: Equatable {
    case notSignedIn
    case quotaExceeded
    case networkUnavailable
    case unknown(String)

    var userMessage: String {
        switch self {
        case .notSignedIn:
            return "Sign in to iCloud to sync across devices"
        case .quotaExceeded:
            return "iCloud storage full. Data safe locally."
        case .networkUnavailable:
            return "Offline. Changes sync when connected."
        case .unknown(let message):
            return message
        }
    }

    var actionLabel: String? {
        switch self {
        case .notSignedIn:
            return "Open Settings"
        case .quotaExceeded:
            return "Manage Storage"
        case .networkUnavailable:
            return nil
        case .unknown:
            return nil
        }
    }

    var systemImage: String {
        switch self {
        case .notSignedIn:
            return "icloud.slash"
        case .quotaExceeded:
            return "exclamationmark.icloud"
        case .networkUnavailable:
            return "wifi.slash"
        case .unknown:
            return "exclamationmark.icloud"
        }
    }

    var iconColor: Color {
        switch self {
        case .notSignedIn:
            return Theme.textTertiary
        case .quotaExceeded:
            return Theme.statusOverdue
        case .networkUnavailable:
            return Theme.textTertiary
        case .unknown:
            return Theme.statusOverdue
        }
    }

    /// Whether this error is transient and eligible for automatic retry
    var isTransient: Bool {
        switch self {
        case .networkUnavailable, .unknown:
            return true
        case .notSignedIn, .quotaExceeded:
            return false
        }
    }
}

/// Represents the current state of iCloud sync
enum SyncState: Equatable {
    case idle
    case syncing
    case synced
    case error(SyncError)
    case disabled
    case noAccount

    var displayText: String {
        switch self {
        case .idle:
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .synced:
            return "Synced"
        case .error(let syncError):
            return syncError.userMessage
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

/// Consolidated service for monitoring and reporting iCloud sync status
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

    // MARK: - Private State

    private let container = CKContainer(identifier: "iCloud.com.418-studio.checkpoint")
    private var networkMonitor: NWPathMonitor?
    private var cancellables = Set<AnyCancellable>()
    private var isNetworkAvailable = true
    private var retryState = RetryState()
    private let isTestInstance: Bool

    // MARK: - Retry State

    private struct RetryState {
        var attempts: Int = 0
        var task: Task<Void, Never>?

        static let maxRetries = 3
        static let baseDelay: TimeInterval = 2

        var nextDelay: TimeInterval {
            RetryState.baseDelay * pow(2, Double(attempts))
        }

        var canRetry: Bool {
            attempts < RetryState.maxRetries
        }

        mutating func reset() {
            attempts = 0
            task?.cancel()
            task = nil
        }
    }

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

    /// Whether the current state is an error
    var hasError: Bool {
        if case .error = syncState {
            return true
        }
        return false
    }

    /// The current error, if any
    var currentError: SyncError? {
        if case .error(let error) = syncState {
            return error
        }
        return nil
    }

    // MARK: - Initialization

    private init() {
        isTestInstance = false
        lastSyncDate = SyncSettings.shared.lastSyncDate

        setupNetworkMonitor()
        setupRemoteChangeObserver()

        Task {
            await checkAccountStatus()
        }
    }

    /// For testing - allows creating instances without starting monitors
    init(forTesting: Bool) {
        isTestInstance = true
        // Don't start monitors during testing
    }

    nonisolated deinit {}

    // MARK: - Account Status

    /// Check if user has an iCloud account and update state accordingly
    func checkAccountStatus() async {
        do {
            let accountStatus = try await container.accountStatus()

            switch accountStatus {
            case .available:
                hasICloudAccount = true
                if !isSyncEnabled {
                    syncState = .disabled
                } else if isNetworkAvailable {
                    // Clear transient errors when account is available
                    if case .error(let error) = syncState, error != .quotaExceeded {
                        syncState = .idle
                    } else if case .noAccount = syncState {
                        syncState = .idle
                    } else if case .syncing = syncState {
                        // Keep syncing
                    } else if case .error(.quotaExceeded) = syncState {
                        // Keep quota error - requires user action
                    } else {
                        syncState = .idle
                    }
                }
            case .noAccount, .restricted, .couldNotDetermine:
                hasICloudAccount = false
                if isSyncEnabled {
                    syncState = .noAccount
                }
            case .temporarilyUnavailable:
                hasICloudAccount = true
                if !isNetworkAvailable {
                    syncState = .error(.networkUnavailable)
                }
            @unknown default:
                hasICloudAccount = false
                syncState = .error(.unknown("Unable to determine iCloud status"))
            }
        } catch {
            hasICloudAccount = false
            if isSyncEnabled {
                syncState = .error(.unknown(error.localizedDescription))
                scheduleRetryIfNeeded(for: .unknown(error.localizedDescription))
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
        retryState.reset()

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
        retryState.reset()

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
        let syncError = mapError(from: error)
        syncState = .error(syncError)
        scheduleRetryIfNeeded(for: syncError)
    }

    /// Update state when sync is toggled
    func syncSettingChanged(enabled: Bool) {
        if enabled {
            Task {
                await checkAccountStatus()
            }
        } else {
            syncState = .disabled
            retryState.reset()
        }
    }

    // MARK: - Settings Actions

    /// Open iOS Settings app
    func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    /// Open iCloud Storage management
    func openStorageSettings() {
        #if os(iOS)
        if let url = URL(string: "App-prefs:CASTLE") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    /// Stop monitoring (call before deallocation if needed)
    func stopMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
        retryState.reset()
    }

    // MARK: - Retry Logic

    /// Schedule a retry attempt for transient errors
    private func scheduleRetryIfNeeded(for error: SyncError) {
        guard error.isTransient, retryState.canRetry else { return }

        let delay = retryState.nextDelay
        retryState.attempts += 1

        retryState.task?.cancel()
        retryState.task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.checkAccountStatus()
        }
    }

    // MARK: - Error Mapping

    /// Convert CloudKit errors to structured SyncError
    private func mapError(from error: Error) -> SyncError {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return .networkUnavailable
            case .quotaExceeded:
                return .quotaExceeded
            case .notAuthenticated:
                return .notSignedIn
            case .serverResponseLost, .serviceUnavailable, .zoneBusy:
                return .unknown(ckError.localizedDescription)
            default:
                return .unknown("Sync error")
            }
        }
        return .unknown("Sync error")
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitor() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { @MainActor in
                self.handleNetworkChange(path)
            }
        }
        networkMonitor?.start(queue: DispatchQueue.global(qos: .utility))
    }

    private func handleNetworkChange(_ path: NWPath) {
        let wasAvailable = isNetworkAvailable
        isNetworkAvailable = path.status == .satisfied

        if !isNetworkAvailable && wasAvailable {
            // Network just went offline
            syncState = .error(.networkUnavailable)
        } else if isNetworkAvailable && !wasAvailable {
            // Network just came back online
            if case .error(.networkUnavailable) = syncState {
                syncState = .idle
            }
            retryState.reset()
            // Re-check iCloud status
            Task {
                await checkAccountStatus()
            }
        }
    }

    // MARK: - Remote Change Observer

    private func setupRemoteChangeObserver() {
        NotificationCenter.default.publisher(
            for: .NSPersistentStoreRemoteChange
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.didReceiveRemoteChanges()
        }
        .store(in: &cancellables)
    }
}
