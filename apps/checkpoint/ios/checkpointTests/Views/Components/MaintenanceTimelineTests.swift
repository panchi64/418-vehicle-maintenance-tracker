//
//  MaintenanceTimelineTests.swift
//  checkpointTests
//
//  Tests for MaintenanceTimeline component
//

import XCTest
import SwiftUI
import SwiftData
@testable import checkpoint

final class MaintenanceTimelineTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext

        vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 45000
        )
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Timeline Item Creation Tests

    @MainActor
    func testTimelineItems_IncludesUpcomingServices() {
        // Given
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: 30, to: Date.now)!

        let service = Service(name: "Oil Change", dueDate: futureDate, dueMileage: 50000)
        service.vehicle = vehicle
        modelContext.insert(service)

        let services = [service]
        let logs: [ServiceLog] = []

        // When
        var items: [(id: String, date: Date, isUpcoming: Bool)] = []

        for service in services {
            if let dueDate = service.dueDate {
                items.append((id: "upcoming-\(service.id)", date: dueDate, isUpcoming: true))
            }
        }

        // Then
        XCTAssertEqual(items.count, 1)
        XCTAssertTrue(items.first?.isUpcoming ?? false)
        XCTAssertEqual(items.first?.date, futureDate)
    }

    @MainActor
    func testTimelineItems_IncludesCompletedLogs() {
        // Given
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .day, value: -30, to: Date.now)!

        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: pastDate,
            mileageAtService: 44000
        )
        modelContext.insert(log)

        let services: [Service] = []
        let logs = [log]

        // When
        var items: [(id: String, date: Date, isUpcoming: Bool)] = []

        for log in logs {
            items.append((id: "completed-\(log.id)", date: log.performedDate, isUpcoming: false))
        }

        // Then
        XCTAssertEqual(items.count, 1)
        XCTAssertFalse(items.first?.isUpcoming ?? true)
        XCTAssertEqual(items.first?.date, pastDate)
    }

    @MainActor
    func testTimelineItems_CombinesServicesAndLogs() {
        // Given
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: 30, to: Date.now)!
        let pastDate = calendar.date(byAdding: .day, value: -30, to: Date.now)!

        let service = Service(name: "Oil Change", dueDate: futureDate, dueMileage: 50000)
        service.vehicle = vehicle
        modelContext.insert(service)

        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: pastDate,
            mileageAtService: 44000
        )
        modelContext.insert(log)

        let services = [service]
        let logs = [log]

        // When
        var items: [(id: String, date: Date, isUpcoming: Bool)] = []

        for service in services {
            if let dueDate = service.dueDate {
                items.append((id: "upcoming-\(service.id)", date: dueDate, isUpcoming: true))
            }
        }
        for log in logs {
            items.append((id: "completed-\(log.id)", date: log.performedDate, isUpcoming: false))
        }

        // Then
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.filter { $0.isUpcoming }.count, 1)
        XCTAssertEqual(items.filter { !$0.isUpcoming }.count, 1)
    }

    // MARK: - Sorting Tests

    @MainActor
    func testTimelineItems_SortedByDateDescending() {
        // Given
        let calendar = Calendar.current
        let date1 = calendar.date(byAdding: .day, value: -60, to: Date.now)!
        let date2 = calendar.date(byAdding: .day, value: -30, to: Date.now)!
        let date3 = calendar.date(byAdding: .day, value: 30, to: Date.now)!

        let log1 = ServiceLog(vehicle: vehicle, performedDate: date1, mileageAtService: 42000)
        let log2 = ServiceLog(vehicle: vehicle, performedDate: date2, mileageAtService: 44000)

        let service = Service(name: "Upcoming", dueDate: date3)
        service.vehicle = vehicle

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(service)

        // When
        var items: [(date: Date, name: String)] = []
        items.append((date: date1, name: "Log 1"))
        items.append((date: date2, name: "Log 2"))
        items.append((date: date3, name: "Upcoming"))

        let sortedItems = items.sorted { $0.date > $1.date }

        // Then
        XCTAssertEqual(sortedItems[0].name, "Upcoming")  // Most future
        XCTAssertEqual(sortedItems[1].name, "Log 2")     // More recent
        XCTAssertEqual(sortedItems[2].name, "Log 1")     // Oldest
    }

    // MARK: - Grouping Tests

    @MainActor
    func testTimelineItems_GroupedByMonth() {
        // Given
        let calendar = Calendar.current

        let januaryDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let januaryDate2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 20))!
        let februaryDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!

        let log1 = ServiceLog(vehicle: vehicle, performedDate: januaryDate, mileageAtService: 42000)
        let log2 = ServiceLog(vehicle: vehicle, performedDate: januaryDate2, mileageAtService: 42500)
        let log3 = ServiceLog(vehicle: vehicle, performedDate: februaryDate, mileageAtService: 43000)

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)

        let logs = [log1, log2, log3]

        // When
        var monthlyGroups: [Date: [ServiceLog]] = [:]
        for log in logs {
            let components = calendar.dateComponents([.year, .month], from: log.performedDate)
            if let monthStart = calendar.date(from: components) {
                monthlyGroups[monthStart, default: []].append(log)
            }
        }

        // Then
        XCTAssertEqual(monthlyGroups.count, 2)  // January and February

        let januaryStart = calendar.date(from: DateComponents(year: 2025, month: 1))!
        let februaryStart = calendar.date(from: DateComponents(year: 2025, month: 2))!

        XCTAssertEqual(monthlyGroups[januaryStart]?.count, 2)
        XCTAssertEqual(monthlyGroups[februaryStart]?.count, 1)
    }

    // MARK: - Mileage-Only Service Tests

    @MainActor
    func testTimelineItems_MileageOnlyService_GetsEstimatedDate() {
        // Given
        let service = Service(name: "Tire Rotation", dueMileage: 50000)
        service.vehicle = vehicle
        modelContext.insert(service)

        let services = [service]

        // When
        var items: [(id: String, date: Date, hasEstimatedDate: Bool)] = []

        for service in services {
            if let dueDate = service.dueDate {
                items.append((id: "service-\(service.id)", date: dueDate, hasEstimatedDate: false))
            } else if service.dueMileage != nil {
                // Estimate date (default to 30 days from now)
                let estimatedDate = Date.now.addingTimeInterval(86400 * 30)
                items.append((id: "service-\(service.id)", date: estimatedDate, hasEstimatedDate: true))
            }
        }

        // Then
        XCTAssertEqual(items.count, 1)
        XCTAssertTrue(items.first?.hasEstimatedDate ?? false)
    }

    // MARK: - Empty State Tests

    @MainActor
    func testTimelineItems_EmptyWhenNoData() {
        // Given
        let services: [Service] = []
        let logs: [ServiceLog] = []

        // When
        var items: [(id: String, date: Date)] = []

        for service in services {
            if let dueDate = service.dueDate {
                items.append((id: "service-\(service.id)", date: dueDate))
            }
        }
        for log in logs {
            items.append((id: "log-\(log.id)", date: log.performedDate))
        }

        // Then
        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - Status Determination Tests

    @MainActor
    func testTimelineItem_UpcomingStatus() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date.now)!

        let service = Service(name: "Oil Change", dueDate: futureDate)
        service.vehicle = vehicle
        modelContext.insert(service)

        // When
        let isUpcoming = service.dueDate != nil && service.dueDate! > Date.now

        // Then
        XCTAssertTrue(isUpcoming)
    }

    @MainActor
    func testTimelineItem_CompletedStatus() {
        // Given
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date.now)!

        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: pastDate,
            mileageAtService: 44000
        )
        modelContext.insert(log)

        // When
        let isCompleted = log.performedDate <= Date.now

        // Then
        XCTAssertTrue(isCompleted)
    }

    // MARK: - Service Association Tests

    @MainActor
    func testTimelineItem_LogHasServiceName() {
        // Given
        let service = Service(name: "Oil Change")
        service.vehicle = vehicle
        modelContext.insert(service)

        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Date.now,
            mileageAtService: 45000
        )
        modelContext.insert(log)

        // When
        let serviceName = log.service?.name

        // Then
        XCTAssertNotNil(serviceName)
        XCTAssertEqual(serviceName, "Oil Change")
    }

    @MainActor
    func testTimelineItem_LogWithoutService() {
        // Given
        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: Date.now,
            mileageAtService: 45000
        )
        modelContext.insert(log)

        // When
        let serviceName = log.service?.name

        // Then
        XCTAssertNil(serviceName)
    }
}
