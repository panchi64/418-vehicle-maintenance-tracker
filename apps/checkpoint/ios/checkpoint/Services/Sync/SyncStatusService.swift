//
//  SyncStatusService.swift
//  checkpoint
//
//  Observes iCloud sync — the iCloud account, `NSPersistentCloudKitContainer`
//  events, and the network path — and holds the result as plain state. The
//  mapping from those inputs to what Settings shows lives in `SyncStatus.swift`.
//

import Foundation
import CloudKit
import CoreData
import Network
import Combine

@Observable
@MainActor
final class SyncStatusService {
    static let shared = SyncStatusService()

    // MARK: - Observable State

    private(set) var account: SyncAccountStatus = .unknown

    private(set) var activity: SyncActivity

    /// Whether existing Checkpoint data was found in iCloud (from a previous install)
    private(set) var hasExistingCloudData: Bool = false

    // MARK: - Derived

    var syncState: SyncState { activity.state }

    /// Last completed import or export; persisted so it survives relaunch.
    var lastSyncDate: Date? { activity.lastSuccess }

    var hasICloudAccount: Bool { account == .available }

    /// The current error, if any
    var currentError: SyncError? {
        if case .error(let error) = syncState { return error }
        return nil
    }

    // MARK: - Private

    private let container = CKContainer(identifier: SyncSettings.cloudKitContainerID)
    private let persistsLastSync: Bool
    private var networkMonitor: NWPathMonitor?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        persistsLastSync = true
        activity = SyncActivity(lastSuccess: SyncSettings.shared.lastSyncDate)
    }

    /// A detached instance for tests: never starts observers, never persists.
    init(forTesting: Bool) {
        persistsLastSync = false
        activity = SyncActivity()
    }

    // MARK: - Monitoring

    /// Start observing container events, account changes and the network.
    /// Called once the running store is CloudKit-backed; idempotent. Without
    /// it (sync off, onboarding, the unit-test host) nothing is observed.
    func startMonitoring() {
        guard cancellables.isEmpty else { return }

        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.checkAccountStatus() }
            }
            .store(in: &cancellables)

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let offline = path.status != .satisfied
            Task { @MainActor in
                self?.activity.isOffline = offline
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .utility))
        networkMonitor = monitor
    }

    // MARK: - Account Status

    /// Read (never request) the iCloud account status.
    func checkAccountStatus() async {
        do {
            account = SyncAccountStatus(try await container.accountStatus())
        } catch {
            account = .unknown
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

    // MARK: - Events

    /// Fold one event into the activity tally, persisting a new sync date.
    func apply(_ event: SyncEvent) {
        let previous = activity.lastSuccess
        activity.apply(event)
        if persistsLastSync, activity.lastSuccess != previous {
            SyncSettings.shared.lastSyncDate = activity.lastSuccess
        }
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
            as? NSPersistentCloudKitContainer.Event else { return }

        let kind: SyncEvent.Kind
        switch event.type {
        case .setup: kind = .setup
        case .import: kind = .import
        case .export: kind = .export
        @unknown default: return
        }

        apply(SyncEvent(
            id: event.identifier,
            kind: kind,
            endDate: event.endDate,
            succeeded: event.succeeded,
            error: event.error.map(SyncError.init)
        ))
    }
}
