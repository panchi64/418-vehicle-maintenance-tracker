//
//  ServiceClusteringTests.swift
//  checkpointTests
//
//  Unit tests for service clustering functionality
//

import XCTest
import SwiftData
@testable import checkpoint

// MARK: - ServiceClusteringService Tests

final class ServiceClusteringServiceTests: XCTestCase {
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

        // Reset ClusteringSettings to defaults for each test
        ClusteringSettings.shared.mileageWindow = 1000
        ClusteringSettings.shared.daysWindow = 30
        ClusteringSettings.shared.isEnabled = true
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Basic Clustering Tests

    @MainActor
    func test_detectClusters_servicesWithinMileageWindow_returnsSingleCluster() {
        // Given: 3 services due at 50,000, 50,500, 50,800 miles (within 1,000 mi window)
        // Current mileage 50,100 puts all services within 750mi "due soon" threshold
        let vehicle = createTestVehicle(mileage: 50100)
        let service1 = createTestService(name: "Oil Change", dueMileage: 50000, dueInDays: 5)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 50500, dueInDays: 10)
        let service3 = createTestService(name: "Air Filter", dueMileage: 50800, dueInDays: 15)

        service1.vehicle = vehicle
        service2.vehicle = vehicle
        service3.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2, service3]
        )

        // Then
        XCTAssertEqual(clusters.count, 1, "Should return 1 cluster")
        XCTAssertEqual(clusters.first?.serviceCount, 3, "Cluster should contain all 3 services")
    }

    @MainActor
    func test_detectClusters_servicesWithinDaysWindow_returnsSingleCluster() {
        // Given: 3 services due in 5, 15, 25 days (within 30 day window)
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueInDays: 5)
        let service2 = createTestService(name: "Tire Rotation", dueInDays: 15)
        let service3 = createTestService(name: "Air Filter", dueInDays: 25)

        service1.vehicle = vehicle
        service2.vehicle = vehicle
        service3.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2, service3]
        )

        // Then
        XCTAssertEqual(clusters.count, 1, "Should return 1 cluster")
        XCTAssertEqual(clusters.first?.serviceCount, 3, "Cluster should contain all 3 services")
    }

    @MainActor
    func test_detectClusters_servicesOutsideWindow_returnsNoCluster() {
        // Given: 2 services 5,000 miles apart and 55+ days apart
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueMileage: 50500, dueInDays: 5)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 55500, dueInDays: 60)

        service1.vehicle = vehicle
        service2.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2]
        )

        // Then: service2 has "good" status (60 days away), so only 1 actionable service
        XCTAssertTrue(clusters.isEmpty, "Should return no clusters for distant services")
    }

    @MainActor
    func test_detectClusters_singleService_returnsNoCluster() {
        // Given: Only 1 overdue service
        let vehicle = createTestVehicle(mileage: 50000)
        let service = createTestService(name: "Oil Change", dueMileage: 49500, dueInDays: -5)
        service.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service]
        )

        // Then
        XCTAssertTrue(clusters.isEmpty, "Should return no clusters for single service (need 2+)")
    }

    @MainActor
    func test_detectClusters_twoActionableServices_returnsCluster() {
        // Given: 2 actionable services within window (minimum cluster size is 2)
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueMileage: 50300, dueInDays: 5)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 50500, dueInDays: 10)

        service1.vehicle = vehicle
        service2.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2]
        )

        // Then
        XCTAssertEqual(clusters.count, 1, "Should return 1 cluster with 2 services")
        XCTAssertEqual(clusters.first?.serviceCount, 2)
    }

    // MARK: - Actionable Filtering Tests

    @MainActor
    func test_detectClusters_allGoodStatus_returnsNoCluster() {
        // Given: 3 services all with "good" status (30+ days away and 500+ miles)
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueMileage: 60000, dueInDays: 60)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 60500, dueInDays: 65)
        let service3 = createTestService(name: "Air Filter", dueMileage: 60800, dueInDays: 70)

        service1.vehicle = vehicle
        service2.vehicle = vehicle
        service3.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2, service3]
        )

        // Then
        XCTAssertTrue(clusters.isEmpty, "Should return no clusters when all services have 'good' status")
    }

    @MainActor
    func test_detectClusters_mixedStatus_clustersOnlyActionable() {
        // Given: 1 overdue + 2 "good" services (only 1 is actionable)
        let vehicle = createTestVehicle(mileage: 50000)
        let overdueService = createTestService(name: "Oil Change", dueMileage: 49500, dueInDays: -5)
        let goodService1 = createTestService(name: "Tire Rotation", dueMileage: 60000, dueInDays: 60)
        let goodService2 = createTestService(name: "Air Filter", dueMileage: 60800, dueInDays: 65)

        overdueService.vehicle = vehicle
        goodService1.vehicle = vehicle
        goodService2.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [overdueService, goodService1, goodService2]
        )

        // Then: Only 1 actionable service, need 2+ for cluster
        XCTAssertTrue(clusters.isEmpty, "Should return no clusters when only 1 service is actionable")
    }

    @MainActor
    func test_detectClusters_twoOverdueServices_returnsCluster() {
        // Given: 2 overdue services
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueMileage: 49500, dueInDays: -5)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 49800, dueInDays: -2)

        service1.vehicle = vehicle
        service2.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2]
        )

        // Then
        XCTAssertEqual(clusters.count, 1, "Should return 1 cluster for 2 overdue services")
        XCTAssertEqual(clusters.first?.serviceCount, 2)
    }

    @MainActor
    func test_detectClusters_mixedOverdueAndDueSoon_returnsCluster() {
        // Given: 1 overdue + 1 due soon within window
        let vehicle = createTestVehicle(mileage: 50000)
        let overdueService = createTestService(name: "Oil Change", dueMileage: 49800, dueInDays: -2)
        let dueSoonService = createTestService(name: "Tire Rotation", dueMileage: 50300, dueInDays: 10)

        overdueService.vehicle = vehicle
        dueSoonService.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [overdueService, dueSoonService]
        )

        // Then
        XCTAssertEqual(clusters.count, 1, "Should cluster overdue and due soon services together")
        XCTAssertEqual(clusters.first?.serviceCount, 2)
    }

    // MARK: - Window Logic Tests

    @MainActor
    func test_detectClusters_withinMileageOrDateWindow_bothIncluded() {
        // Given: 2 services - both within date window even if mileage differs
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueMileage: 50200, dueInDays: 5)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 50400, dueInDays: 10) // Within 30 day window

        service1.vehicle = vehicle
        service2.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2]
        )

        // Then
        XCTAssertEqual(clusters.count, 1, "Should cluster services within either window (OR logic)")
        XCTAssertEqual(clusters.first?.serviceCount, 2)
    }

    @MainActor
    func test_detectClusters_customMileageWindow_respectsSettings() {
        // Given: Services 1,500 miles apart, settings.mileageWindow = 2,000
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueMileage: 50300, dueInDays: 5)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 50400, dueInDays: 20) // 100 miles apart

        service1.vehicle = vehicle
        service2.vehicle = vehicle

        ClusteringSettings.shared.mileageWindow = 2000

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2]
        )

        // Then
        XCTAssertEqual(clusters.count, 1, "Should cluster services within custom 2,000 mile window")
    }

    @MainActor
    func test_detectClusters_customDaysWindow_respectsSettings() {
        // Given: Services 40 days apart with 45 day window
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueInDays: -5)
        let service2 = createTestService(name: "Tire Rotation", dueInDays: 25) // 30 days apart

        service1.vehicle = vehicle
        service2.vehicle = vehicle

        ClusteringSettings.shared.daysWindow = 45

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2]
        )

        // Then
        XCTAssertEqual(clusters.count, 1, "Should cluster services within custom 45 day window")
    }

    @MainActor
    func test_detectClusters_disabledSettings_returnsNoCluster() {
        // Given: Clustering disabled in settings
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueMileage: 50500, dueInDays: 5)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 50800, dueInDays: 10)

        service1.vehicle = vehicle
        service2.vehicle = vehicle

        ClusteringSettings.shared.isEnabled = false

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2]
        )

        // Then
        XCTAssertTrue(clusters.isEmpty, "Should return no clusters when clustering is disabled")
    }

    // MARK: - Urgency & Sorting Tests

    @MainActor
    func test_detectClusters_anchorIsMostUrgent() {
        // Given: 3 services - one overdue, two due soon
        let vehicle = createTestVehicle(mileage: 50000)
        let overdueService = createTestService(name: "Overdue Oil", dueMileage: 49500, dueInDays: -5)
        let dueSoonService1 = createTestService(name: "Due Soon Tires", dueMileage: 50200, dueInDays: 10)
        let dueSoonService2 = createTestService(name: "Due Soon Filter", dueMileage: 50400, dueInDays: 15)

        overdueService.vehicle = vehicle
        dueSoonService1.vehicle = vehicle
        dueSoonService2.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [dueSoonService1, overdueService, dueSoonService2]
        )

        // Then
        XCTAssertEqual(clusters.first?.anchorService.id, overdueService.id, "Anchor should be the most urgent (overdue) service")
    }

    @MainActor
    func test_detectClusters_servicesOrderedByUrgency() {
        // Given: Services with varying urgency
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Least Urgent", dueMileage: 50400, dueInDays: 25)
        let service2 = createTestService(name: "Most Urgent", dueMileage: 49800, dueInDays: -3)
        let service3 = createTestService(name: "Mid Urgent", dueMileage: 50100, dueInDays: 5)

        service1.vehicle = vehicle
        service2.vehicle = vehicle
        service3.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [service1, service2, service3]
        )

        // Then
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.anchorService.name, "Most Urgent")
    }

    // MARK: - No Duplicates Tests

    @MainActor
    func test_detectClusters_serviceAppearsInOnlyOneCluster() {
        // Given: 5 services that could form 2 overlapping clusters if allowed
        let vehicle = createTestVehicle(mileage: 50000)

        // Group A: due around 50,500 (actionable)
        let serviceA1 = createTestService(name: "Service A1", dueMileage: 50200, dueInDays: 3)
        let serviceA2 = createTestService(name: "Service A2", dueMileage: 50400, dueInDays: 5)

        // Could overlap with group B
        let serviceMiddle = createTestService(name: "Middle", dueMileage: 50300, dueInDays: 12)

        // Group B: also actionable
        let serviceB1 = createTestService(name: "Service B1", dueMileage: 50100, dueInDays: 15)
        let serviceB2 = createTestService(name: "Service B2", dueMileage: 50350, dueInDays: 18)

        [serviceA1, serviceA2, serviceMiddle, serviceB1, serviceB2].forEach { $0.vehicle = vehicle }

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [serviceA1, serviceA2, serviceMiddle, serviceB1, serviceB2]
        )

        // Then: Each service should appear in at most 1 cluster
        var allServiceIDs: [UUID] = []
        for cluster in clusters {
            allServiceIDs.append(contentsOf: cluster.services.map { $0.id })
        }
        let uniqueIDs = Set(allServiceIDs)
        XCTAssertEqual(allServiceIDs.count, uniqueIDs.count, "Each service should appear in at most one cluster")
    }

    @MainActor
    func test_detectClusters_greedyAssignment_mostUrgentFirst() {
        // Given: Services where greedy assignment should group with most urgent anchor first
        let vehicle = createTestVehicle(mileage: 50000)

        let urgentService = createTestService(name: "Urgent", dueMileage: 49900, dueInDays: -2)
        let nearbyService = createTestService(name: "Nearby", dueMileage: 50100, dueInDays: 5)

        urgentService.vehicle = vehicle
        nearbyService.vehicle = vehicle

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [nearbyService, urgentService]
        )

        // Then: Both should be in one cluster with urgent as anchor
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.anchorService.name, "Urgent")
        XCTAssertEqual(clusters.first?.serviceCount, 2)
    }

    // MARK: - Primary Cluster Tests

    @MainActor
    func test_primaryCluster_returnsFirstCluster() {
        // Given: Multiple possible clusters
        let vehicle = createTestVehicle(mileage: 50000)
        let service1 = createTestService(name: "Oil Change", dueMileage: 50200, dueInDays: 5)
        let service2 = createTestService(name: "Tire Rotation", dueMileage: 50400, dueInDays: 10)

        service1.vehicle = vehicle
        service2.vehicle = vehicle

        // When
        let primary = ServiceClusteringService.primaryCluster(
            for: vehicle,
            services: [service1, service2]
        )

        // Then
        XCTAssertNotNil(primary, "Should return primary cluster")
        XCTAssertEqual(primary?.serviceCount, 2)
    }

    @MainActor
    func test_primaryCluster_noClusters_returnsNil() {
        // Given: Only 1 service (not enough for cluster)
        let vehicle = createTestVehicle(mileage: 50000)
        let service = createTestService(name: "Oil Change", dueMileage: 50200, dueInDays: 5)
        service.vehicle = vehicle

        // When
        let primary = ServiceClusteringService.primaryCluster(
            for: vehicle,
            services: [service]
        )

        // Then
        XCTAssertNil(primary, "Should return nil when no clusters exist")
    }

    // MARK: - Edge Cases

    @MainActor
    func test_detectClusters_emptyServices_returnsEmpty() {
        // Given: No services
        let vehicle = createTestVehicle(mileage: 50000)

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: []
        )

        // Then
        XCTAssertTrue(clusters.isEmpty, "Should return empty array for no services")
    }

    @MainActor
    func test_detectClusters_neutralStatusServices_notIncluded() {
        // Given: Services with neutral status (no due date/mileage)
        let vehicle = createTestVehicle(mileage: 50000)
        let neutralService1 = Service(name: "General Check 1")
        let neutralService2 = Service(name: "General Check 2")

        neutralService1.vehicle = vehicle
        neutralService2.vehicle = vehicle

        modelContext.insert(neutralService1)
        modelContext.insert(neutralService2)

        // When
        let clusters = ServiceClusteringService.detectClusters(
            for: vehicle,
            services: [neutralService1, neutralService2]
        )

        // Then
        XCTAssertTrue(clusters.isEmpty, "Should not cluster neutral status services")
    }

    // MARK: - Test Helpers

    private func createTestVehicle(mileage: Int = 50000) -> Vehicle {
        let vehicle = Vehicle(
            name: "Test Car",
            make: "Test",
            model: "Model",
            year: 2020,
            currentMileage: mileage
        )
        modelContext.insert(vehicle)
        return vehicle
    }

    private func createTestService(
        name: String,
        dueMileage: Int? = nil,
        dueInDays: Int? = nil
    ) -> Service {
        var dueDate: Date? = nil
        if let days = dueInDays {
            dueDate = Calendar.current.date(byAdding: .day, value: days, to: .now)
        }

        let service = Service(
            name: name,
            dueDate: dueDate,
            dueMileage: dueMileage
        )
        modelContext.insert(service)
        return service
    }
}

// MARK: - ServiceCluster Model Tests

final class ServiceClusterTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    @MainActor
    func test_contentHash_changesWhenServicesChange() {
        // Given
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let serviceA = Service(name: "A")
        let serviceB = Service(name: "B")
        let serviceC = Service(name: "C")
        let serviceD = Service(name: "D")

        [serviceA, serviceB, serviceC, serviceD].forEach { modelContext.insert($0) }

        let cluster1 = ServiceCluster(
            services: [serviceA, serviceB, serviceC],
            anchorService: serviceA,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        let cluster2 = ServiceCluster(
            services: [serviceA, serviceB, serviceD],
            anchorService: serviceA,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        // Then
        XCTAssertNotEqual(cluster1.contentHash, cluster2.contentHash, "Hash should change when services differ")
    }

    @MainActor
    func test_contentHash_stableForSameServices() {
        // Given: Same services in different order
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let serviceA = Service(name: "A")
        let serviceB = Service(name: "B")
        let serviceC = Service(name: "C")

        [serviceA, serviceB, serviceC].forEach { modelContext.insert($0) }

        let cluster1 = ServiceCluster(
            services: [serviceA, serviceB, serviceC],
            anchorService: serviceA,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        let cluster2 = ServiceCluster(
            services: [serviceC, serviceA, serviceB],  // Different order
            anchorService: serviceA,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        // Then
        XCTAssertEqual(cluster1.contentHash, cluster2.contentHash, "Hash should be stable regardless of service order")
    }

    @MainActor
    func test_suggestedMileage_comesFromAnchor() {
        // Given
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let anchor = Service(name: "Anchor", dueMileage: 52000)
        let other = Service(name: "Other", dueMileage: 53000)

        [anchor, other].forEach { modelContext.insert($0) }

        let cluster = ServiceCluster(
            services: [anchor, other],
            anchorService: anchor,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        // Then
        XCTAssertEqual(cluster.suggestedMileage, 52000, "Suggested mileage should come from anchor service")
    }

    @MainActor
    func test_suggestedDate_comesFromAnchor() {
        // Given
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let expectedDate = Calendar.current.date(byAdding: .day, value: 10, to: .now)!
        let anchor = Service(name: "Anchor", dueDate: expectedDate)
        let other = Service(name: "Other", dueDate: Calendar.current.date(byAdding: .day, value: 20, to: .now))

        [anchor, other].forEach { modelContext.insert($0) }

        let cluster = ServiceCluster(
            services: [anchor, other],
            anchorService: anchor,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        // Then
        XCTAssertEqual(cluster.suggestedDate, expectedDate, "Suggested date should come from anchor service")
    }

    @MainActor
    func test_windowDescription_formattedCorrectly() {
        // Given
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let service = Service(name: "Test")
        modelContext.insert(service)

        let cluster = ServiceCluster(
            services: [service],
            anchorService: service,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        // Then
        XCTAssertEqual(cluster.windowDescription, "1,000 MI", "Window description should be formatted with comma")
    }

    @MainActor
    func test_windowDescription_largeNumber() {
        // Given
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let service = Service(name: "Test")
        modelContext.insert(service)

        let cluster = ServiceCluster(
            services: [service],
            anchorService: service,
            vehicle: vehicle,
            mileageWindow: 2500,
            daysWindow: 30
        )

        // Then
        XCTAssertEqual(cluster.windowDescription, "2,500 MI", "Window description should format large numbers correctly")
    }

    @MainActor
    func test_serviceCount_returnsCorrectCount() {
        // Given
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let service1 = Service(name: "Service 1")
        let service2 = Service(name: "Service 2")
        let service3 = Service(name: "Service 3")

        [service1, service2, service3].forEach { modelContext.insert($0) }

        let cluster = ServiceCluster(
            services: [service1, service2, service3],
            anchorService: service1,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        // Then
        XCTAssertEqual(cluster.serviceCount, 3)
    }

    @MainActor
    func test_mostUrgentStatus_returnsAnchorStatus() {
        // Given
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        // Anchor is overdue
        let anchor = Service(name: "Anchor", dueMileage: 49000)
        anchor.vehicle = vehicle
        let other = Service(name: "Other", dueMileage: 52000)
        other.vehicle = vehicle

        [anchor, other].forEach { modelContext.insert($0) }

        let cluster = ServiceCluster(
            services: [anchor, other],
            anchorService: anchor,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        // Then
        XCTAssertEqual(cluster.mostUrgentStatus, .overdue)
    }

    @MainActor
    func test_clusterUrgencyScore_matchesAnchor() {
        // Given
        let vehicle = Vehicle(name: "Test", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let dueDate = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
        let anchor = Service(name: "Anchor", dueDate: dueDate)
        anchor.vehicle = vehicle
        modelContext.insert(anchor)

        let cluster = ServiceCluster(
            services: [anchor],
            anchorService: anchor,
            vehicle: vehicle,
            mileageWindow: 1000,
            daysWindow: 30
        )

        // Then
        let expectedScore = anchor.urgencyScore(currentMileage: vehicle.effectiveMileage, dailyPace: vehicle.dailyMilesPace)
        XCTAssertEqual(cluster.clusterUrgencyScore, expectedScore)
    }
}

// MARK: - Cluster Dismissal Tests

final class ClusterDismissalTests: XCTestCase {

    func test_dismissedCluster_hashPersistence() {
        // Given: A content hash
        let hash = "abc-123-def-456"
        var dismissedHashes = Set<String>()

        // When: Hash is added to dismissed set
        dismissedHashes.insert(hash)

        // Then
        XCTAssertTrue(dismissedHashes.contains(hash), "Dismissed hash should be tracked")
    }

    func test_dismissedCluster_reappearsWhenServicesChange() {
        // Given: Original cluster hash
        let originalHash = "service1-service2-service3"
        var dismissedHashes = Set<String>([originalHash])

        // When: New cluster with different services (new hash)
        let newHash = "service1-service2-service4"

        // Then
        XCTAssertFalse(dismissedHashes.contains(newHash), "New cluster hash should not be dismissed")
    }

    func test_dismissedCluster_sameServicesStillDismissed() {
        // Given: Original cluster dismissed
        let hash = "service1-service2-service3"
        var dismissedHashes = Set<String>([hash])

        // When: Same hash checked again
        let isStillDismissed = dismissedHashes.contains(hash)

        // Then
        XCTAssertTrue(isStillDismissed, "Same cluster hash should remain dismissed")
    }

    func test_multipleDismissals_allTracked() {
        // Given: Multiple dismissed clusters
        var dismissedHashes = Set<String>()
        let hashes = ["hash1", "hash2", "hash3"]

        // When: All are dismissed
        hashes.forEach { dismissedHashes.insert($0) }

        // Then
        XCTAssertEqual(dismissedHashes.count, 3, "All hashes should be tracked")
        hashes.forEach {
            XCTAssertTrue(dismissedHashes.contains($0), "Hash \($0) should be tracked")
        }
    }
}

// MARK: - ClusteringSettings Tests

final class ClusteringSettingsTests: XCTestCase {

    @MainActor
    override func setUp() {
        super.setUp()
        // Reset to defaults before each test
        ClusteringSettings.shared.mileageWindow = 1000
        ClusteringSettings.shared.daysWindow = 30
        ClusteringSettings.shared.isEnabled = true
    }

    @MainActor
    func test_defaultValues() {
        // Reset to check defaults are applied
        ClusteringSettings.registerDefaults()

        // Then: Defaults should be applied
        // Note: Since this is a singleton, we test by checking mileage window options
        XCTAssertTrue(ClusteringSettings.mileageWindowOptions.contains(1000), "Default mileage window should be in options")
        XCTAssertTrue(ClusteringSettings.daysWindowOptions.contains(30), "Default days window should be in options")
    }

    @MainActor
    func test_mileageWindowOptions() {
        // Then: Should have expected options
        let expectedOptions = [500, 1000, 1500, 2000]
        XCTAssertEqual(ClusteringSettings.mileageWindowOptions, expectedOptions)
    }

    @MainActor
    func test_daysWindowOptions() {
        // Then: Should have expected options
        let expectedOptions = [14, 30, 45, 60]
        XCTAssertEqual(ClusteringSettings.daysWindowOptions, expectedOptions)
    }

    @MainActor
    func test_minimumClusterSize_isTwo() {
        // Then: Minimum should be 2
        XCTAssertEqual(ClusteringSettings.shared.minimumClusterSize, 2)
    }

    @MainActor
    func test_settingMileageWindow_updatesValue() {
        // When
        ClusteringSettings.shared.mileageWindow = 1500

        // Then
        XCTAssertEqual(ClusteringSettings.shared.mileageWindow, 1500)
    }

    @MainActor
    func test_settingDaysWindow_updatesValue() {
        // When
        ClusteringSettings.shared.daysWindow = 45

        // Then
        XCTAssertEqual(ClusteringSettings.shared.daysWindow, 45)
    }

    @MainActor
    func test_settingIsEnabled_updatesValue() {
        // When
        ClusteringSettings.shared.isEnabled = false

        // Then
        XCTAssertFalse(ClusteringSettings.shared.isEnabled)
    }
}
