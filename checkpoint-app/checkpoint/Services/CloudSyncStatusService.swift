//
//  CloudSyncStatusService.swift
//  checkpoint
//
//  Service for monitoring CloudKit sync status and iCloud availability
//

import Foundation
import SwiftUI
import CloudKit
import CoreData
import Network
import Combine

/// Service for monitoring CloudKit sync status
@Observable
@MainActor
final class CloudSyncStatusService {
    // MARK: - Types

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case error(CloudSyncError)
    }

    enum CloudSyncError: Equatable {
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
    }

    // MARK: - Properties

    static let shared = CloudSyncStatusService()

    private(set) var status: SyncStatus = .idle
    private(set) var lastSyncDate: Date?
    private(set) var iCloudAvailable: Bool = false

    private let container = CKContainer(identifier: "iCloud.com.418-studio.checkpoint")
    private nonisolated(unsafe) var networkMonitor: NWPathMonitor?
    private var cancellables = Set<AnyCancellable>()
    private var isNetworkAvailable = true

    // MARK: - Computed Properties

    var hasError: Bool {
        if case .error = status {
            return true
        }
        return false
    }

    var currentError: CloudSyncError? {
        if case .error(let error) = status {
            return error
        }
        return nil
    }

    var statusDisplayText: String {
        switch status {
        case .idle:
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .error(let error):
            return error.userMessage
        }
    }

    // MARK: - Initialization

    private init() {
        setupNetworkMonitor()
        setupRemoteChangeObserver()
        Task {
            await checkiCloudStatus()
        }
    }

    // For testing - allows creating instances without starting monitors
    init(forTesting: Bool) {
        // Don't start monitors during testing
    }

    // MARK: - Public Methods

    /// Check iCloud account status
    func checkiCloudStatus() async {
        do {
            let accountStatus = try await container.accountStatus()

            switch accountStatus {
            case .available:
                iCloudAvailable = true
                // Only clear error if we're not having network issues
                if isNetworkAvailable {
                    if case .error(.notSignedIn) = status {
                        status = .idle
                    } else if case .error(.quotaExceeded) = status {
                        // Keep quota error - it doesn't auto-resolve
                    } else if case .error(.networkUnavailable) = status {
                        status = .idle
                    } else if case .idle = status {
                        // Keep idle
                    } else if case .syncing = status {
                        // Keep syncing
                    } else {
                        status = .idle
                    }
                }
            case .noAccount:
                iCloudAvailable = false
                status = .error(.notSignedIn)
            case .restricted, .couldNotDetermine:
                iCloudAvailable = false
                status = .error(.notSignedIn)
            case .temporarilyUnavailable:
                // Account temporarily unavailable - treat as network issue
                iCloudAvailable = true
                if !isNetworkAvailable {
                    status = .error(.networkUnavailable)
                }
            @unknown default:
                iCloudAvailable = false
                status = .error(.unknown("Unable to determine iCloud status"))
            }
        } catch {
            iCloudAvailable = false
            status = .error(.unknown(error.localizedDescription))
        }
    }

    /// Called when a remote change notification is received
    func handleRemoteChange() {
        // Mark as syncing briefly, then idle
        status = .syncing
        lastSyncDate = Date()

        // After a short delay, return to idle (simulating sync completion)
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            if case .syncing = status {
                status = .idle
            }
        }
    }

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
        // Deep link to iCloud storage settings
        if let url = URL(string: "App-prefs:CASTLE") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    /// Stop monitoring (call before deallocation if needed)
    func stopMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }

    // MARK: - Private Methods

    private func setupNetworkMonitor() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handleNetworkChange(path)
            }
        }
        networkMonitor?.start(queue: DispatchQueue.global(qos: .utility))
    }

    private func handleNetworkChange(_ path: NWPath) {
        let wasAvailable = isNetworkAvailable
        isNetworkAvailable = path.status == .satisfied

        if !isNetworkAvailable && wasAvailable {
            // Network just went offline
            status = .error(.networkUnavailable)
        } else if isNetworkAvailable && !wasAvailable {
            // Network just came back online
            if case .error(.networkUnavailable) = status {
                status = .idle
            }
            // Re-check iCloud status
            Task {
                await checkiCloudStatus()
            }
        }
    }

    private func setupRemoteChangeObserver() {
        NotificationCenter.default.publisher(
            for: .NSPersistentStoreRemoteChange
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.handleRemoteChange()
        }
        .store(in: &cancellables)
    }

    nonisolated deinit {
        networkMonitor?.cancel()
    }
}
