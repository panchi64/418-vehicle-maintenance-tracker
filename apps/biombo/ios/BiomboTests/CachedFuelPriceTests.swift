import XCTest
import SwiftData
@testable import Biombo

final class CachedFuelPriceTests: XCTestCase {
    var modelContainer: ModelContainer!

    @MainActor
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: CachedFuelPrice.self, PriceHistoryPoint.self, CachedBrand.self,
            configurations: config
        )
    }

    @MainActor
    func testFreshnessBuckets() {
        let now = Date()
        let fresh = makePrice(reportedAt: now.addingTimeInterval(-3600))           // 1h old
        let aging = makePrice(reportedAt: now.addingTimeInterval(-12 * 3600))      // 12h old
        let stale = makePrice(reportedAt: now.addingTimeInterval(-36 * 3600))      // 36h old

        XCTAssertEqual(fresh.freshness, .fresh)
        XCTAssertEqual(aging.freshness, .aging)
        XCTAssertEqual(stale.freshness, .stale)
    }

    @MainActor
    func testIsExpired() {
        let now = Date()
        let live = makePrice(reportedAt: now, expiresAt: now.addingTimeInterval(3600))
        let expired = makePrice(reportedAt: now.addingTimeInterval(-7200), expiresAt: now.addingTimeInterval(-3600))
        XCTAssertFalse(live.isExpired)
        XCTAssertTrue(expired.isExpired)
    }

    @MainActor
    private func makePrice(reportedAt: Date, expiresAt: Date = Date().addingTimeInterval(48 * 3600)) -> CachedFuelPrice {
        CachedFuelPrice(
            recordID: UUID().uuidString,
            stationName: "Test Station",
            latitude: 18.0,
            longitude: -66.0,
            regularPrice: 0.98,
            source: "daco",
            reportedAt: reportedAt,
            expiresAt: expiresAt
        )
    }
}
