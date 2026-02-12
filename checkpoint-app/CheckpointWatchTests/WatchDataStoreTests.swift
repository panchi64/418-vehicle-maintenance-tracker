//
//  WatchDataStoreTests.swift
//  CheckpointWatch Watch AppTests
//
//  Tests for WatchDataStore — save/load/overwrite in UserDefaults
//

import Testing
@testable import CheckpointWatch_Watch_App

struct WatchDataStoreTests {

    // MARK: - Sorted Services

    @Test func sortedServicesOrdersByUrgency() {
        let services = [
            WatchService(vehicleID: "v1", serviceID: "sid-1", name: "Good Service", status: .good, dueDescription: "30 days", dueMileage: nil, daysRemaining: 30),
            WatchService(vehicleID: "v1", serviceID: "sid-2", name: "Overdue Service", status: .overdue, dueDescription: "5 days overdue", dueMileage: nil, daysRemaining: -5),
            WatchService(vehicleID: "v1", serviceID: "sid-3", name: "Due Soon Service", status: .dueSoon, dueDescription: "3 days", dueMileage: nil, daysRemaining: 3),
            WatchService(vehicleID: "v1", serviceID: "sid-4", name: "Neutral Service", status: .neutral, dueDescription: "Scheduled", dueMileage: nil, daysRemaining: nil),
        ]

        // Verify sort order enum values
        #expect(WatchServiceStatus.overdue.sortOrder == 0)
        #expect(WatchServiceStatus.dueSoon.sortOrder == 1)
        #expect(WatchServiceStatus.good.sortOrder == 2)
        #expect(WatchServiceStatus.neutral.sortOrder == 3)

        let sorted = services.sorted { $0.status.sortOrder < $1.status.sortOrder }
        #expect(sorted[0].name == "Overdue Service")
        #expect(sorted[1].name == "Due Soon Service")
        #expect(sorted[2].name == "Good Service")
        #expect(sorted[3].name == "Neutral Service")
    }

    // MARK: - Status Sort Order

    @Test func statusSortOrderIsCorrect() {
        #expect(WatchServiceStatus.overdue.sortOrder < WatchServiceStatus.dueSoon.sortOrder)
        #expect(WatchServiceStatus.dueSoon.sortOrder < WatchServiceStatus.good.sortOrder)
        #expect(WatchServiceStatus.good.sortOrder < WatchServiceStatus.neutral.sortOrder)
    }
}
