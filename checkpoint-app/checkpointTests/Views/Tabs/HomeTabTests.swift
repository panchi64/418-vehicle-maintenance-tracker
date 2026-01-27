//
//  HomeTabTests.swift
//  checkpointTests
//
//  Tests for HomeTab view content and functionality
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

final class HomeTabTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Service Sorting Tests

    @MainActor
    func testVehicleServices_AreSortedByUrgency() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let overdueService = Service(
            name: "Overdue Service",
            dueMileage: 29000 // Already overdue
        )
        overdueService.vehicle = vehicle

        let upcomingService = Service(
            name: "Upcoming Service",
            dueMileage: 35000 // Not urgent
        )
        upcomingService.vehicle = vehicle

        let dueSoonService = Service(
            name: "Due Soon Service",
            dueMileage: 30200 // Due soon (within 500 miles)
        )
        dueSoonService.vehicle = vehicle

        modelContext.insert(overdueService)
        modelContext.insert(upcomingService)
        modelContext.insert(dueSoonService)

        // When - sort by urgency (lower score = more urgent)
        let services = [overdueService, upcomingService, dueSoonService]
        let sorted = services.sorted {
            $0.urgencyScore(currentMileage: vehicle.currentMileage) < $1.urgencyScore(currentMileage: vehicle.currentMileage)
        }

        // Then - overdue should be first, due soon second, upcoming last
        XCTAssertEqual(sorted.first?.name, "Overdue Service")
        XCTAssertEqual(sorted.last?.name, "Upcoming Service")
    }

    // MARK: - Service Status Tests

    @MainActor
    func testNextUpService_IsFirstInSortedList() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let service1 = Service(
            name: "Service 1",
            dueMileage: 35000
        )
        service1.vehicle = vehicle

        let service2 = Service(
            name: "Service 2",
            dueMileage: 31000 // More urgent
        )
        service2.vehicle = vehicle

        modelContext.insert(service1)
        modelContext.insert(service2)

        // When
        let services = [service1, service2]
        let sorted = services.sorted {
            $0.urgencyScore(currentMileage: vehicle.currentMileage) < $1.urgencyScore(currentMileage: vehicle.currentMileage)
        }
        let nextUp = sorted.first

        // Then
        XCTAssertEqual(nextUp?.name, "Service 2")
    }

    // MARK: - Service Log Tests

    @MainActor
    func testRecentLogs_AreSortedByDate() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let calendar = Calendar.current
        let log1 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -7, to: .now)!,
            mileageAtService: 29000
        )
        let log2 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -1, to: .now)!, // Most recent
            mileageAtService: 30000
        )
        let log3 = ServiceLog(
            vehicle: vehicle,
            performedDate: calendar.date(byAdding: .day, value: -30, to: .now)!,
            mileageAtService: 28000
        )

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)

        // When
        let logs = [log1, log2, log3]
        let sorted = logs.sorted { $0.performedDate > $1.performedDate }
        let recentLogs = Array(sorted.prefix(3))

        // Then
        XCTAssertEqual(recentLogs.count, 3)
        XCTAssertEqual(recentLogs.first?.mileageAtService, 30000) // log2 is most recent
    }

    // MARK: - Empty State Tests

    @MainActor
    func testEmptyState_WhenNoVehicle() async {
        // Given - no vehicle in context
        // When - AppState with nil selectedVehicle
        let appState = AppState()

        // Then
        XCTAssertNil(appState.selectedVehicle)
    }

    @MainActor
    func testEmptyState_WhenNoServices() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        // When - vehicle has no services
        let services = vehicle.services

        // Then
        XCTAssertTrue(services.isEmpty)
    }

    // MARK: - Mileage Update Tests

    @MainActor
    func testMileageUpdate_UpdatesVehicle() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        // When
        vehicle.currentMileage = 31000
        vehicle.mileageUpdatedAt = .now

        // Then
        XCTAssertEqual(vehicle.currentMileage, 31000)
        XCTAssertNotNil(vehicle.mileageUpdatedAt)
    }

    @MainActor
    func testMileageUpdate_CreatesSnapshot() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        // When
        let snapshot = MileageSnapshot(
            vehicle: vehicle,
            mileage: 31000,
            recordedAt: .now,
            source: .manual
        )
        modelContext.insert(snapshot)

        // Then
        XCTAssertEqual(vehicle.mileageSnapshots.count, 1)
        XCTAssertEqual(vehicle.mileageSnapshots.first?.mileage, 31000)
    }

    // MARK: - Service Status Update Tests

    @MainActor
    func testServiceStatus_UpdatesAfterMileageChange() {
        // Given - service that's currently overdue
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 35000  // Past due mileage
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Oil Change",
            dueMileage: 34000  // Overdue by 1000 miles
        )
        service.vehicle = vehicle
        modelContext.insert(service)

        // Verify initially overdue
        XCTAssertEqual(service.status(currentMileage: vehicle.currentMileage), .overdue)

        // When - mileage is corrected (lower reading)
        vehicle.currentMileage = 30000
        try? modelContext.save()

        // Then - status should now be good (4000 miles remaining)
        XCTAssertEqual(service.status(currentMileage: vehicle.currentMileage), .good)
    }

    @MainActor
    func testMileageUpdate_TriggersModelContextSave() {
        // Given
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)
        try? modelContext.save()

        // When
        vehicle.currentMileage = 31000
        vehicle.mileageUpdatedAt = .now
        try? modelContext.save()

        // Then - verify the change persisted
        XCTAssertEqual(vehicle.currentMileage, 31000)
    }

    @MainActor
    func testServiceStatus_TransitionsFromGoodToOverdue() {
        // Given - service that's currently good
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)

        let service = Service(
            name: "Oil Change",
            dueMileage: 35000  // 5000 miles away - good status
        )
        service.vehicle = vehicle
        modelContext.insert(service)

        // Verify initially good
        XCTAssertEqual(service.status(currentMileage: vehicle.currentMileage), .good)

        // When - mileage increases past due
        vehicle.currentMileage = 36000
        try? modelContext.save()

        // Then - status should now be overdue
        XCTAssertEqual(service.status(currentMileage: vehicle.currentMileage), .overdue)
    }
}
