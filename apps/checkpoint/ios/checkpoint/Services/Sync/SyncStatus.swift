//
//  SyncStatus.swift
//  checkpoint
//
//  The pure half of iCloud sync status: value types and the mappings from
//  CloudKit's raw inputs (account status, container events, errors) to what
//  Settings shows. Nothing here observes anything — `SyncStatusService` feeds
//  it — so every mapping is testable without an iCloud account.
//

import SwiftUI
import CloudKit

// MARK: - Error

/// A sync failure, reduced to the cases the user can do something about.
/// Never carries raw `NSError` text: anything unrecognized is `.unknown`.
enum SyncError: Equatable {
    case notSignedIn
    case quotaExceeded
    case networkUnavailable
    case unknown

    /// Classify a CloudKit / Core Data+CloudKit error. Export failures usually
    /// arrive as `.partialFailure` wrapping per-record errors, and Core Data
    /// wraps the CloudKit error as an underlying error, so both are unwrapped.
    init(_ error: Error) {
        self = Self.classify(error as NSError, depth: 0) ?? .unknown
    }

    /// `NSCloudKitMirroringDelegate`'s "no iCloud account" code. No public
    /// constant exists for it.
    nonisolated static let coreDataNoAccountCode = 134400

    private static func classify(_ error: NSError, depth: Int) -> SyncError? {
        guard depth < 3 else { return nil }

        if error.domain == CKError.errorDomain, let code = CKError.Code(rawValue: error.code) {
            switch code {
            case .quotaExceeded:
                return .quotaExceeded
            case .networkUnavailable, .networkFailure:
                return .networkUnavailable
            case .notAuthenticated:
                return .notSignedIn
            case .partialFailure:
                let partials = error.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error] ?? [:]
                let classified = partials.values.compactMap { classify($0 as NSError, depth: depth + 1) }
                // The most actionable reason wins.
                for candidate in [SyncError.quotaExceeded, .notSignedIn, .networkUnavailable] where classified.contains(candidate) {
                    return candidate
                }
            default:
                break
            }
        }

        if error.domain == NSURLErrorDomain {
            switch URLError.Code(rawValue: error.code) {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut,
                 .cannotConnectToHost, .dataNotAllowed, .internationalRoamingOff:
                return .networkUnavailable
            default:
                break
            }
        }

        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError,
           let classified = classify(underlying, depth: depth + 1) {
            return classified
        }

        // Core Data+CloudKit reports a missing account in its own domain
        // ("Unable to initialize without an iCloud account"), not as a
        // CKError; left unclassified it read as an unknown failure. Checked
        // after the underlying error, which is more specific when present.
        if error.domain == NSCocoaErrorDomain && error.code == Self.coreDataNoAccountCode {
            return .notSignedIn
        }
        return nil
    }

    var systemImage: String {
        switch self {
        case .notSignedIn: return "icloud.slash"
        case .networkUnavailable: return "wifi.slash"
        case .quotaExceeded, .unknown: return "exclamationmark.icloud"
        }
    }

    var iconColor: Color {
        switch self {
        case .notSignedIn, .networkUnavailable: return Theme.textTertiary
        case .quotaExceeded, .unknown: return Theme.statusOverdue
        }
    }
}

// MARK: - Account

/// Whether this device has an iCloud account CloudKit can use.
enum SyncAccountStatus: Equatable {
    /// Not checked yet, or iCloud couldn't say.
    case unknown
    case available
    /// No account, restricted (Screen Time / MDM), or needing re-sign-in.
    case unavailable

    init(_ status: CKAccountStatus) {
        switch status {
        case .available: self = .available
        case .noAccount, .restricted, .temporarilyUnavailable: self = .unavailable
        case .couldNotDetermine: self = .unknown
        @unknown default: self = .unknown
        }
    }
}

// MARK: - Activity

/// What the container is doing right now.
enum SyncState: Equatable {
    case idle
    case syncing
    case error(SyncError)
}

/// One `NSPersistentCloudKitContainer.Event`, copied into a value so the
/// reducer below can be driven by tests.
struct SyncEvent: Equatable {
    enum Kind: Int, Comparable {
        case setup, export, `import`

        static func < (lhs: Kind, rhs: Kind) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let id: UUID
    let kind: Kind
    /// `nil` while the operation is still running.
    let endDate: Date?
    let succeeded: Bool
    let error: SyncError?
}

/// The running tally of container events. Setup, import and export overlap,
/// so "syncing" is "any event still in flight", and a failure is cleared only
/// by a later success of the same kind — an import finishing says nothing
/// about an export that ran out of iCloud storage.
struct SyncActivity: Equatable {
    private(set) var inFlight: Set<UUID> = []
    private(set) var failures: [SyncEvent.Kind: SyncError] = [:]
    /// Last time data actually moved (import or export). Setup doesn't count.
    private(set) var lastSuccess: Date?
    var isOffline = false

    init(lastSuccess: Date? = nil) {
        self.lastSuccess = lastSuccess
    }

    mutating func apply(_ event: SyncEvent) {
        guard let endDate = event.endDate else {
            inFlight.insert(event.id)
            return
        }
        inFlight.remove(event.id)
        if event.succeeded {
            failures[event.kind] = nil
            if event.kind != .setup {
                lastSuccess = max(lastSuccess ?? endDate, endDate)
            }
        } else {
            failures[event.kind] = event.error ?? .unknown
        }
    }

    var state: SyncState {
        if isOffline { return .error(.networkUnavailable) }
        if !inFlight.isEmpty { return .syncing }
        if let failure = failures.sorted(by: { $0.key < $1.key }).first?.value {
            return .error(failure)
        }
        return .idle
    }
}

// MARK: - Display

/// Everything the Settings status row depends on, in one value.
struct SyncStatusInputs: Equatable {
    /// The toggle's current value.
    var isEnabled: Bool
    /// Whether this launch's store was built with CloudKit.
    var isActiveThisLaunch: Bool
    var account: SyncAccountStatus
    var state: SyncState
    var lastSyncDate: Date?
}

/// What Settings shows under the iCloud Sync toggle.
enum SyncStatusDisplay: Equatable {
    /// The toggle disagrees with the running store: the toggle's own
    /// "Takes effect next launch" note stands in for a status.
    case pendingRestart
    case unavailable
    case syncing
    /// `nil` until the first import or export completes.
    case upToDate(lastSynced: Date?)
    case failed(SyncError)

    /// `nil` when sync is off — the toggle already says so.
    static func resolve(_ inputs: SyncStatusInputs) -> SyncStatusDisplay? {
        if inputs.isEnabled != inputs.isActiveThisLaunch { return .pendingRestart }
        guard inputs.isEnabled else { return nil }
        if inputs.account == .unavailable { return .unavailable }
        switch inputs.state {
        case .syncing: return .syncing
        case .error(.notSignedIn): return .unavailable
        case .error(let error): return .failed(error)
        case .idle: return .upToDate(lastSynced: inputs.lastSyncDate)
        }
    }

    /// The short reason shown under "Couldn't sync", for the cases that have one.
    static func failureReason(_ error: SyncError) -> String? {
        switch error {
        case .quotaExceeded: return L10n.syncErrorQuotaExceeded
        case .networkUnavailable: return L10n.syncErrorOffline
        case .notSignedIn, .unknown: return nil
        }
    }
}
