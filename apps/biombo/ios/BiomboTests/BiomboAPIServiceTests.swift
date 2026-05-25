import XCTest
@testable import Biombo

final class BiomboAPIServiceTests: XCTestCase {
    func testDACOStationDecoding() throws {
        let json = """
        {
          "id": "s-1",
          "brand": "Puma",
          "stationName": "Puma San Patricio",
          "municipality": "Guaynabo",
          "latitude": 18.418,
          "longitude": -66.075,
          "regular": 0.98,
          "premium": 1.12,
          "diesel": 1.05
        }
        """.data(using: .utf8)!
        let station = try JSONDecoder().decode(DACOStationDTO.self, from: json)
        XCTAssertEqual(station.brand, "Puma")
        XCTAssertEqual(station.regular, 0.98)
        XCTAssertEqual(station.premium, 1.12)
        XCTAssertEqual(station.diesel, 1.05)
    }

    func testPricesResponseDecoding() throws {
        let json = """
        {
          "snapshotId": "snap-1",
          "scrapedAt": "2026-04-22T06:00:00Z",
          "daco": [],
          "community": []
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(PricesResponse.self, from: json)
        XCTAssertEqual(response.snapshotId, "snap-1")
        XCTAssertTrue(response.daco.isEmpty)
        XCTAssertTrue(response.community.isEmpty)
    }
}
