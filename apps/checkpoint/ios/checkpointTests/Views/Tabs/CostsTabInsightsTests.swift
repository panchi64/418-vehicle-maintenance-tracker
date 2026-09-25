//
//  CostsTabInsightsTests.swift
//  checkpointTests
//
//  Anomaly detection behind the Costs tab's OUTLIER row tag. The CostsTab
//  view needs @Query + AppState, so the algorithm is reachable through
//  `CostsInsightsCore`.
//

import XCTest
import SwiftData
@testable import checkpoint

final class CostsTabInsightsTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self, ServiceVisit.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext

        vehicle = Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 30000
        )
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @MainActor
    private func makeLog(daysAgo: Int, cost: Decimal, category: CostCategory) -> ServiceLog {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        let log = ServiceLog(
            vehicle: vehicle,
            performedDate: date,
            mileageAtService: 30000,
            cost: cost,
            costCategory: category
        )
        modelContext.insert(log)
        return log
    }

    // MARK: - Anomaly Detection

    @MainActor
    func test_detectAnomalies_fewEvents_returnsEmpty() {
        let l1 = makeLog(daysAgo: 1, cost: 100, category: .maintenance)
        let l2 = makeLog(daysAgo: 2, cost: 5000, category: .repair)
        let events: [ExpenseEvent] = [.standalone(l1), .standalone(l2)]
        XCTAssertTrue(CostsInsightsCore.detectAnomalies(events: events).isEmpty)
    }

    @MainActor
    func test_detectAnomalies_outlierAboveTwoXAverage_returnsID() {
        let cheap1 = makeLog(daysAgo: 1, cost: 50, category: .maintenance)
        let cheap2 = makeLog(daysAgo: 2, cost: 50, category: .maintenance)
        let cheap3 = makeLog(daysAgo: 3, cost: 50, category: .maintenance)
        let huge = makeLog(daysAgo: 4, cost: 2000, category: .repair)
        let events: [ExpenseEvent] = [
            .standalone(cheap1), .standalone(cheap2),
            .standalone(cheap3), .standalone(huge)
        ]

        let anomalies = CostsInsightsCore.detectAnomalies(events: events)
        XCTAssertTrue(anomalies.contains(huge.id))
        XCTAssertFalse(anomalies.contains(cheap1.id))
    }

    @MainActor
    func test_detectAnomalies_allSimilarAmounts_returnsEmpty() {
        let a = makeLog(daysAgo: 1, cost: 100, category: .maintenance)
        let b = makeLog(daysAgo: 2, cost: 110, category: .maintenance)
        let c = makeLog(daysAgo: 3, cost: 95, category: .maintenance)
        let events: [ExpenseEvent] = [.standalone(a), .standalone(b), .standalone(c)]
        XCTAssertTrue(CostsInsightsCore.detectAnomalies(events: events).isEmpty)
    }
}
