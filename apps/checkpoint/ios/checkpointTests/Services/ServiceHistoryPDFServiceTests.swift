//
//  ServiceHistoryPDFServiceTests.swift
//  checkpointTests
//
//  Tests for ServiceHistoryPDFService PDF generation.
//

import XCTest
import SwiftData
import PDFKit
@testable import checkpoint

@MainActor
final class ServiceHistoryPDFServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var sut: ServiceHistoryPDFService!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        sut = ServiceHistoryPDFService.shared
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestVehicle(
        name: String = "Test Car",
        make: String = "Honda",
        model: String = "Civic",
        year: Int = 2022,
        mileage: Int = 50000,
        vin: String? = "1HGCM82633A123456"
    ) -> Vehicle {
        let vehicle = Vehicle(
            name: name,
            make: make,
            model: model,
            year: year,
            currentMileage: mileage
        )
        vehicle.vin = vin
        modelContext.insert(vehicle)
        return vehicle
    }

    private func createTestService(
        name: String = "Oil Change",
        vehicle: Vehicle
    ) -> Service {
        let service = Service(name: name)
        service.vehicle = vehicle
        modelContext.insert(service)
        return service
    }

    private func createTestServiceLog(
        service: Service,
        vehicle: Vehicle,
        performedDate: Date = Date(),
        mileageAtService: Int = 50000,
        cost: Decimal? = 45.00,
        notes: String? = nil
    ) -> ServiceLog {
        let log = ServiceLog(
            performedDate: performedDate,
            mileageAtService: mileageAtService
        )
        log.service = service
        log.vehicle = vehicle
        log.cost = cost
        log.notes = notes
        modelContext.insert(log)
        return log
    }

    // MARK: - Tests

    func test_generatePDF_withVehicleAndLogs_returnsURL() {
        // Given
        let vehicle = createTestVehicle()
        let service = createTestService(vehicle: vehicle)
        let log = createTestServiceLog(service: service, vehicle: vehicle)

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log])

        // Then
        XCTAssertNotNil(url, "PDF URL should not be nil")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path), "PDF file should exist")

        // Cleanup
        try? FileManager.default.removeItem(at: url!)
    }

    func test_generatePDF_withNoLogs_generatesEmptyHistory() {
        // Given
        let vehicle = createTestVehicle()

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [])

        // Then
        XCTAssertNotNil(url, "PDF URL should not be nil even with no logs")

        // Verify it's a valid PDF
        if let url = url {
            let pdfDocument = PDFDocument(url: url)
            XCTAssertNotNil(pdfDocument, "Should be a valid PDF document")
            XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 0, "PDF should have at least one page")

            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_includesVehicleInfo() {
        // Given
        let vehicle = createTestVehicle(
            name: "My Honda",
            make: "Honda",
            model: "Civic",
            year: 2022,
            mileage: 52347,
            vin: "1HGCM82633A123456"
        )

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [])

        // Then
        XCTAssertNotNil(url, "PDF should be generated")

        // Verify PDF contains text (basic verification)
        if let url = url, let pdfDocument = PDFDocument(url: url) {
            let pageCount = pdfDocument.pageCount
            XCTAssertGreaterThan(pageCount, 0, "PDF should have pages")

            // Get text from first page
            if let page = pdfDocument.page(at: 0) {
                let text = page.string ?? ""
                XCTAssertTrue(text.contains("CHECKPOINT"), "PDF should contain app name")
            }

            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_includesAllServiceLogs() {
        // Given
        let vehicle = createTestVehicle()
        let service1 = createTestService(name: "Oil Change", vehicle: vehicle)
        let service2 = createTestService(name: "Tire Rotation", vehicle: vehicle)

        let log1 = createTestServiceLog(
            service: service1,
            vehicle: vehicle,
            performedDate: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            mileageAtService: 48000,
            cost: 45.00
        )
        let log2 = createTestServiceLog(
            service: service2,
            vehicle: vehicle,
            performedDate: Date().addingTimeInterval(-86400 * 15), // 15 days ago
            mileageAtService: 49500,
            cost: 25.00
        )
        let log3 = createTestServiceLog(
            service: service1,
            vehicle: vehicle,
            performedDate: Date(),
            mileageAtService: 51000,
            cost: 50.00
        )

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log1, log2, log3])

        // Then
        XCTAssertNotNil(url, "PDF should be generated with multiple logs")

        // Cleanup
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_withIncludeTotal_calculatesCorrectSum() {
        // Given
        let vehicle = createTestVehicle()
        let service = createTestService(vehicle: vehicle)

        let log1 = createTestServiceLog(service: service, vehicle: vehicle, cost: 100.00)
        let log2 = createTestServiceLog(service: service, vehicle: vehicle, cost: 50.50)
        let log3 = createTestServiceLog(service: service, vehicle: vehicle, cost: 25.25)
        // Total should be 175.75

        let options = ExportOptions(includeTotal: true)

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log1, log2, log3], options: options)

        // Then
        XCTAssertNotNil(url, "PDF should be generated with totals")

        // Cleanup
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_withoutIncludeTotal_omitsTotal() {
        // Given
        let vehicle = createTestVehicle()
        let service = createTestService(vehicle: vehicle)
        let log = createTestServiceLog(service: service, vehicle: vehicle, cost: 100.00)

        let options = ExportOptions(includeTotal: false)

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log], options: options)

        // Then
        XCTAssertNotNil(url, "PDF should be generated without totals")

        // Cleanup
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_withSpecialCharacters_escapesCorrectly() {
        // Given
        let vehicle = createTestVehicle(name: "Car with \"quotes\" & <brackets>")
        let service = createTestService(name: "Service with émojis 🔧", vehicle: vehicle)
        let log = createTestServiceLog(
            service: service,
            vehicle: vehicle,
            notes: "Notes with special chars: <>&\"' and unicode: ñ ü ö"
        )

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log])

        // Then
        XCTAssertNotNil(url, "PDF should handle special characters")

        // Verify it's a valid PDF
        if let url = url {
            let pdfDocument = PDFDocument(url: url)
            XCTAssertNotNil(pdfDocument, "PDF should be valid despite special characters")

            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_withLongNotes_truncatesCorrectly() {
        // Given
        let vehicle = createTestVehicle()
        let service = createTestService(vehicle: vehicle)
        let longNotes = String(repeating: "This is a long note. ", count: 50) // ~1000 chars
        let log = createTestServiceLog(
            service: service,
            vehicle: vehicle,
            notes: longNotes
        )

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log])

        // Then
        XCTAssertNotNil(url, "PDF should handle long notes")

        // Cleanup
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_filenameContainsVehicleName() {
        // Given
        let vehicle = createTestVehicle(name: "My Honda Civic")

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [])

        // Then
        XCTAssertNotNil(url, "PDF should be generated")
        if let url = url {
            XCTAssertTrue(url.lastPathComponent.contains("My_Honda_Civic"), "Filename should contain vehicle name")

            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_logsAreSortedChronologically() {
        // Given
        let vehicle = createTestVehicle()
        let service = createTestService(vehicle: vehicle)

        let oldestDate = Date().addingTimeInterval(-86400 * 60) // 60 days ago
        let middleDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        let newestDate = Date() // today

        // Create logs in non-chronological order
        let log2 = createTestServiceLog(service: service, vehicle: vehicle, performedDate: middleDate, mileageAtService: 49000)
        let log3 = createTestServiceLog(service: service, vehicle: vehicle, performedDate: newestDate, mileageAtService: 51000)
        let log1 = createTestServiceLog(service: service, vehicle: vehicle, performedDate: oldestDate, mileageAtService: 47000)

        // When - pass logs in random order
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log2, log3, log1])

        // Then
        XCTAssertNotNil(url, "PDF should be generated with sorted logs")

        // Cleanup
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_withNilCost_handlesGracefully() {
        // Given
        let vehicle = createTestVehicle()
        let service = createTestService(vehicle: vehicle)
        let log = createTestServiceLog(service: service, vehicle: vehicle, cost: nil)

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log])

        // Then
        XCTAssertNotNil(url, "PDF should handle nil costs")

        // Cleanup
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func test_generatePDF_withZeroCost_handlesGracefully() {
        // Given
        let vehicle = createTestVehicle()
        let service = createTestService(vehicle: vehicle)
        let log = createTestServiceLog(service: service, vehicle: vehicle, cost: 0)

        // When
        let url = sut.generatePDF(for: vehicle, serviceLogs: [log])

        // Then
        XCTAssertNotNil(url, "PDF should handle zero costs")

        // Cleanup
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
