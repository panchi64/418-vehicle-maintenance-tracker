//
//  NHTSAServiceTests.swift
//  checkpointTests
//
//  Tests for NHTSA VIN decoding and recall fetch using mock URL protocol
//

import XCTest
@testable import checkpoint

// MARK: - Mock URL Protocol

final class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: HTTPURLResponse?
    static var mockError: Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = MockURLProtocol.mockResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = MockURLProtocol.mockData {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}

    static func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
    }
}

// MARK: - Test Helpers

private func makeSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func mockHTTPResponse(url: String = "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/test?format=json", statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: url)!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

// MARK: - VIN Decode Tests

final class NHTSAServiceVINDecodeTests: XCTestCase {

    private var service: NHTSAService!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        service = NHTSAService(session: makeSession())
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testDecodeVIN_ValidVIN_ReturnsPopulatedResult() async throws {
        let json = """
        {
            "Results": [{
                "Make": "Toyota",
                "Model": "Camry",
                "ModelYear": "2012",
                "EngineModel": "2AR-FE",
                "DisplacementL": "2.5",
                "FuelTypePrimary": "Gasoline",
                "DriveType": "FWD",
                "BodyClass": "Sedan",
                "ErrorCode": "0",
                "EngineCylinders": "4",
                "EngineHP": "178"
            }]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        let result = try await service.decodeVIN("4T1BF1FK5CU123456")

        XCTAssertEqual(result.make, "Toyota")
        XCTAssertEqual(result.model, "Camry")
        XCTAssertEqual(result.modelYear, 2012)
        XCTAssertTrue(result.engineDescription.contains("2.5L"))
        XCTAssertTrue(result.engineDescription.contains("4-cyl"))
        XCTAssertTrue(result.engineDescription.contains("178 HP"))
        XCTAssertEqual(result.driveType, "FWD")
        XCTAssertEqual(result.bodyClass, "Sedan")
        XCTAssertEqual(result.fuelType, "Gasoline")
        XCTAssertEqual(result.errorCode, "0")
    }

    func testDecodeVIN_PartialResult_ReturnsAvailableFields() async throws {
        let json = """
        {
            "Results": [{
                "Make": "Honda",
                "Model": "Civic",
                "ModelYear": "2020",
                "EngineModel": "",
                "DisplacementL": "",
                "FuelTypePrimary": "",
                "DriveType": "",
                "BodyClass": "",
                "ErrorCode": "1",
                "EngineCylinders": "",
                "EngineHP": ""
            }]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        let result = try await service.decodeVIN("1HGBH41JXMN109186")

        XCTAssertEqual(result.make, "Honda")
        XCTAssertEqual(result.model, "Civic")
        XCTAssertEqual(result.modelYear, 2020)
    }

    func testDecodeVIN_InvalidVIN_ThrowsInvalidVINError() async {
        do {
            _ = try await service.decodeVIN("ABC")
            XCTFail("Expected invalidVIN error")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .invalidVIN)
        }
    }

    func testDecodeVIN_ForbiddenCharacters_ThrowsInvalidVINError() async {
        // VIN with I, O, Q characters should be invalid
        do {
            _ = try await service.decodeVIN("4T1BF1FK5CI123456")  // Contains 'I'
            XCTFail("Expected invalidVIN error")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .invalidVIN)
        }

        do {
            _ = try await service.decodeVIN("4T1BF1FK5CO123456")  // Contains 'O'
            XCTFail("Expected invalidVIN error")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .invalidVIN)
        }

        do {
            _ = try await service.decodeVIN("4T1BF1FK5CQ123456")  // Contains 'Q'
            XCTFail("Expected invalidVIN error")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .invalidVIN)
        }
    }

    func testDecodeVIN_ServerError_ThrowsServerError() async {
        MockURLProtocol.mockData = Data()
        MockURLProtocol.mockResponse = mockHTTPResponse(statusCode: 500)

        do {
            _ = try await service.decodeVIN("4T1BF1FK5CU123456")
            XCTFail("Expected serverError")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .serverError)
        }
    }

    func testDecodeVIN_MalformedJSON_ThrowsDecodingError() async {
        MockURLProtocol.mockData = "not json".data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        do {
            _ = try await service.decodeVIN("4T1BF1FK5CU123456")
            XCTFail("Expected decodingFailed")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .decodingFailed)
        }
    }

    func testDecodeVIN_EmptyResults_ThrowsNoResultsFound() async {
        let json = """
        {"Results": []}
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        do {
            _ = try await service.decodeVIN("4T1BF1FK5CU123456")
            XCTFail("Expected noResultsFound")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .noResultsFound)
        }
    }

    func testDecodeVIN_NetworkUnavailable_ThrowsNetworkError() async {
        MockURLProtocol.mockError = URLError(.notConnectedToInternet)

        do {
            _ = try await service.decodeVIN("4T1BF1FK5CU123456")
            XCTFail("Expected networkUnavailable")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .networkUnavailable)
        }
    }
}

// MARK: - Recall Fetch Tests

final class NHTSAServiceRecallTests: XCTestCase {

    private var service: NHTSAService!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        service = NHTSAService(session: makeSession())
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testFetchRecalls_WithResults_ReturnsRecallList() async throws {
        let json = """
        {
            "Count": 2,
            "results": [
                {
                    "NHTSACampaignNumber": "24V123",
                    "Component": "AIR BAGS",
                    "Summary": "Air bag may not deploy.",
                    "Consequence": "Increased risk of injury.",
                    "Remedy": "Replace air bag module.",
                    "ReportReceivedDate": "01/15/2024",
                    "parkIt": true,
                    "parkOutSide": false
                },
                {
                    "NHTSACampaignNumber": "23V456",
                    "Component": "FUEL SYSTEM",
                    "Summary": "Fuel pump may fail.",
                    "Consequence": "Engine stall.",
                    "Remedy": "Replace fuel pump.",
                    "ReportReceivedDate": "06/20/2023",
                    "parkIt": false,
                    "parkOutSide": false
                }
            ]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse(url: "https://api.nhtsa.gov/recalls/recallsByVehicle?make=Toyota&model=Camry&modelYear=2012")

        let recalls = try await service.fetchRecalls(make: "Toyota", model: "Camry", year: 2012)

        XCTAssertEqual(recalls.count, 2)
        XCTAssertEqual(recalls[0].campaignNumber, "24V123")
        XCTAssertEqual(recalls[0].component, "AIR BAGS")
        XCTAssertEqual(recalls[0].summary, "Air bag may not deploy.")
        XCTAssertEqual(recalls[0].consequence, "Increased risk of injury.")
        XCTAssertEqual(recalls[0].remedy, "Replace air bag module.")
        XCTAssertEqual(recalls[0].reportDate, "01/15/2024")
        XCTAssertTrue(recalls[0].parkIt)
        XCTAssertFalse(recalls[0].parkOutside)
        XCTAssertEqual(recalls[1].campaignNumber, "23V456")
    }

    func testFetchRecalls_NoRecalls_ReturnsEmptyArray() async throws {
        let json = """
        {"Count": 0, "results": []}
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse(url: "https://api.nhtsa.gov/recalls/recallsByVehicle?make=Honda&model=Civic&modelYear=2024")

        let recalls = try await service.fetchRecalls(make: "Honda", model: "Civic", year: 2024)

        XCTAssertTrue(recalls.isEmpty)
    }

    func testFetchRecalls_ServerError_ThrowsServerError() async {
        MockURLProtocol.mockData = Data()
        MockURLProtocol.mockResponse = mockHTTPResponse(statusCode: 500)

        do {
            _ = try await service.fetchRecalls(make: "Toyota", model: "Camry", year: 2012)
            XCTFail("Expected serverError")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .serverError)
        }
    }

    func testFetchRecalls_MalformedJSON_ThrowsDecodingError() async {
        MockURLProtocol.mockData = "garbage".data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        do {
            _ = try await service.fetchRecalls(make: "Toyota", model: "Camry", year: 2012)
            XCTFail("Expected decodingFailed")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .decodingFailed)
        }
    }

    func testFetchRecalls_ParkItFlag_ParsedCorrectly() async throws {
        let json = """
        {
            "Count": 1,
            "results": [{
                "NHTSACampaignNumber": "24V999",
                "Component": "ELECTRICAL",
                "Summary": "Battery fire risk.",
                "Consequence": "Fire.",
                "Remedy": "Dealer update.",
                "ReportReceivedDate": "02/01/2024",
                "parkIt": true,
                "parkOutSide": true
            }]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        let recalls = try await service.fetchRecalls(make: "Ford", model: "Escape", year: 2023)

        XCTAssertEqual(recalls.count, 1)
        XCTAssertTrue(recalls[0].parkIt)
        XCTAssertTrue(recalls[0].parkOutside)
    }
}

// MARK: - Model Tests

final class NHTSAModelTests: XCTestCase {

    func testVINDecodeResult_FieldsPopulated() {
        let result = VINDecodeResult(
            make: "Toyota",
            model: "Camry",
            modelYear: 2012,
            engineDescription: "2.5L 4-cyl 178 HP",
            driveType: "FWD",
            bodyClass: "Sedan",
            fuelType: "Gasoline",
            errorCode: "0"
        )

        XCTAssertEqual(result.make, "Toyota")
        XCTAssertEqual(result.model, "Camry")
        XCTAssertEqual(result.modelYear, 2012)
        XCTAssertEqual(result.engineDescription, "2.5L 4-cyl 178 HP")
        XCTAssertEqual(result.driveType, "FWD")
        XCTAssertEqual(result.bodyClass, "Sedan")
        XCTAssertEqual(result.fuelType, "Gasoline")
        XCTAssertEqual(result.errorCode, "0")
    }

    func testRecallInfo_FieldsPopulated() {
        let recall = RecallInfo(
            campaignNumber: "24V123",
            component: "AIR BAGS",
            summary: "Air bag defect.",
            consequence: "Injury risk.",
            remedy: "Replace module.",
            reportDate: "01/15/2024",
            parkIt: true,
            parkOutside: false
        )

        XCTAssertEqual(recall.campaignNumber, "24V123")
        XCTAssertEqual(recall.component, "AIR BAGS")
        XCTAssertEqual(recall.summary, "Air bag defect.")
        XCTAssertEqual(recall.consequence, "Injury risk.")
        XCTAssertEqual(recall.remedy, "Replace module.")
        XCTAssertEqual(recall.reportDate, "01/15/2024")
        XCTAssertTrue(recall.parkIt)
        XCTAssertFalse(recall.parkOutside)
    }

    func testRecallInfo_HasUniqueID() {
        let recall1 = RecallInfo(
            campaignNumber: "24V123",
            component: "AIR BAGS",
            summary: "", consequence: "", remedy: "",
            reportDate: "", parkIt: false, parkOutside: false
        )
        let recall2 = RecallInfo(
            campaignNumber: "24V123",
            component: "AIR BAGS",
            summary: "", consequence: "", remedy: "",
            reportDate: "", parkIt: false, parkOutside: false
        )

        XCTAssertNotEqual(recall1.id, recall2.id)
    }
}

// MARK: - Cache Tests

final class NHTSAServiceCacheTests: XCTestCase {

    private var service: NHTSAService!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        service = NHTSAService(session: makeSession())
    }

    override func tearDown() async throws {
        await service.clearCache()
        MockURLProtocol.reset()
        try await super.tearDown()
    }

    func testDecodeVIN_SecondCall_ReturnsCachedResult() async throws {
        let json = """
        {
            "Results": [{
                "Make": "Toyota",
                "Model": "Camry",
                "ModelYear": "2012",
                "EngineModel": "",
                "DisplacementL": "",
                "FuelTypePrimary": "",
                "DriveType": "",
                "BodyClass": "",
                "ErrorCode": "0",
                "EngineCylinders": "",
                "EngineHP": ""
            }]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        // First call - hits the network
        let result1 = try await service.decodeVIN("4T1BF1FK5CU123456")
        XCTAssertEqual(result1.make, "Toyota")

        // Clear mock data to prove second call uses cache
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil

        // Second call - should use cache (would fail if it hit network)
        let result2 = try await service.decodeVIN("4T1BF1FK5CU123456")
        XCTAssertEqual(result2.make, "Toyota")
        XCTAssertEqual(result2.model, "Camry")
    }

    func testDecodeVIN_DifferentVINs_NotCached() async throws {
        let json1 = """
        {
            "Results": [{
                "Make": "Toyota",
                "Model": "Camry",
                "ModelYear": "2012",
                "EngineModel": "",
                "DisplacementL": "",
                "FuelTypePrimary": "",
                "DriveType": "",
                "BodyClass": "",
                "ErrorCode": "0",
                "EngineCylinders": "",
                "EngineHP": ""
            }]
        }
        """
        MockURLProtocol.mockData = json1.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        let result1 = try await service.decodeVIN("4T1BF1FK5CU123456")
        XCTAssertEqual(result1.make, "Toyota")

        // Setup different response for second VIN
        let json2 = """
        {
            "Results": [{
                "Make": "Honda",
                "Model": "Civic",
                "ModelYear": "2020",
                "EngineModel": "",
                "DisplacementL": "",
                "FuelTypePrimary": "",
                "DriveType": "",
                "BodyClass": "",
                "ErrorCode": "0",
                "EngineCylinders": "",
                "EngineHP": ""
            }]
        }
        """
        MockURLProtocol.mockData = json2.data(using: .utf8)

        // Different VIN - should hit network
        let result2 = try await service.decodeVIN("1HGBH41JXMN109186")
        XCTAssertEqual(result2.make, "Honda")
    }

    func testDecodeVIN_CaseInsensitive_UsesSameCache() async throws {
        let json = """
        {
            "Results": [{
                "Make": "Toyota",
                "Model": "Camry",
                "ModelYear": "2012",
                "EngineModel": "",
                "DisplacementL": "",
                "FuelTypePrimary": "",
                "DriveType": "",
                "BodyClass": "",
                "ErrorCode": "0",
                "EngineCylinders": "",
                "EngineHP": ""
            }]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        // First call with lowercase
        let result1 = try await service.decodeVIN("4t1bf1fk5cu123456")
        XCTAssertEqual(result1.make, "Toyota")

        // Clear mock to prove cache is used
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil

        // Second call with uppercase - should use same cache entry
        let result2 = try await service.decodeVIN("4T1BF1FK5CU123456")
        XCTAssertEqual(result2.make, "Toyota")
    }

    func testFetchRecalls_SecondCall_ReturnsCachedResult() async throws {
        let json = """
        {
            "Count": 1,
            "results": [{
                "NHTSACampaignNumber": "24V123",
                "Component": "AIR BAGS",
                "Summary": "Test recall",
                "Consequence": "",
                "Remedy": "",
                "ReportReceivedDate": "",
                "parkIt": false,
                "parkOutSide": false
            }]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        // First call
        let recalls1 = try await service.fetchRecalls(make: "Toyota", model: "Camry", year: 2012)
        XCTAssertEqual(recalls1.count, 1)

        // Clear mock to prove cache is used
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil

        // Second call - should use cache
        let recalls2 = try await service.fetchRecalls(make: "Toyota", model: "Camry", year: 2012)
        XCTAssertEqual(recalls2.count, 1)
        XCTAssertEqual(recalls2[0].campaignNumber, "24V123")
    }

    func testFetchRecalls_CaseInsensitive_UsesSameCache() async throws {
        let json = """
        {
            "Count": 1,
            "results": [{
                "NHTSACampaignNumber": "24V123",
                "Component": "AIR BAGS",
                "Summary": "Test recall",
                "Consequence": "",
                "Remedy": "",
                "ReportReceivedDate": "",
                "parkIt": false,
                "parkOutSide": false
            }]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        // First call
        let recalls1 = try await service.fetchRecalls(make: "Toyota", model: "Camry", year: 2012)
        XCTAssertEqual(recalls1.count, 1)

        // Clear mock
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil

        // Second call with different casing - should use same cache
        let recalls2 = try await service.fetchRecalls(make: "TOYOTA", model: "CAMRY", year: 2012)
        XCTAssertEqual(recalls2.count, 1)
    }

    func testFetchRecalls_DifferentVehicle_NotCached() async throws {
        let json1 = """
        {
            "Count": 1,
            "results": [{
                "NHTSACampaignNumber": "24V123",
                "Component": "AIR BAGS",
                "Summary": "Toyota recall",
                "Consequence": "",
                "Remedy": "",
                "ReportReceivedDate": "",
                "parkIt": false,
                "parkOutSide": false
            }]
        }
        """
        MockURLProtocol.mockData = json1.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        let recalls1 = try await service.fetchRecalls(make: "Toyota", model: "Camry", year: 2012)
        XCTAssertEqual(recalls1[0].summary, "Toyota recall")

        // Setup different response
        let json2 = """
        {
            "Count": 1,
            "results": [{
                "NHTSACampaignNumber": "24V456",
                "Component": "BRAKES",
                "Summary": "Honda recall",
                "Consequence": "",
                "Remedy": "",
                "ReportReceivedDate": "",
                "parkIt": false,
                "parkOutSide": false
            }]
        }
        """
        MockURLProtocol.mockData = json2.data(using: .utf8)

        // Different vehicle - should hit network
        let recalls2 = try await service.fetchRecalls(make: "Honda", model: "Civic", year: 2020)
        XCTAssertEqual(recalls2[0].summary, "Honda recall")
    }

    func testClearCache_RemovesCachedData() async throws {
        let json = """
        {
            "Results": [{
                "Make": "Toyota",
                "Model": "Camry",
                "ModelYear": "2012",
                "EngineModel": "",
                "DisplacementL": "",
                "FuelTypePrimary": "",
                "DriveType": "",
                "BodyClass": "",
                "ErrorCode": "0",
                "EngineCylinders": "",
                "EngineHP": ""
            }]
        }
        """
        MockURLProtocol.mockData = json.data(using: .utf8)
        MockURLProtocol.mockResponse = mockHTTPResponse()

        // First call - caches result
        let result1 = try await service.decodeVIN("4T1BF1FK5CU123456")
        XCTAssertEqual(result1.make, "Toyota")

        // Clear cache
        await service.clearCache()

        // Setup different response - if cache still worked, we'd get Toyota
        let json2 = """
        {
            "Results": [{
                "Make": "Honda",
                "Model": "Accord",
                "ModelYear": "2020",
                "EngineModel": "",
                "DisplacementL": "",
                "FuelTypePrimary": "",
                "DriveType": "",
                "BodyClass": "",
                "ErrorCode": "0",
                "EngineCylinders": "",
                "EngineHP": ""
            }]
        }
        """
        MockURLProtocol.mockData = json2.data(using: .utf8)

        // Should get new data since cache was cleared
        let result2 = try await service.decodeVIN("4T1BF1FK5CU123456")
        XCTAssertEqual(result2.make, "Honda", "Cache should have been cleared, returning new API result")
    }
}

// MARK: - NHTSAError Equatable

extension NHTSAError: Equatable {}
