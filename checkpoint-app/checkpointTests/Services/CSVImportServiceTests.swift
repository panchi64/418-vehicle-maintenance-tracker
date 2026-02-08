//
//  CSVImportServiceTests.swift
//  checkpointTests
//
//  Unit tests for CSVImportService: parsing, format detection, column mapping,
//  mileage conversion, date parsing, service grouping, and commit.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class CSVImportServiceTests: XCTestCase {

    var service: CSVImportService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        service = CSVImportService.shared
        service.reset()

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self,
            ServiceAttachment.self, MileageSnapshot.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        service.reset()
        service = nil
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - CSV Line Parsing

    func testParseCSVLine_simple() {
        let result = service.parseCSVLine("a,b,c")
        XCTAssertEqual(result, ["a", "b", "c"])
    }

    func testParseCSVLine_quotedFields() {
        let result = service.parseCSVLine("\"hello, world\",b,c")
        XCTAssertEqual(result, ["hello, world", "b", "c"])
    }

    func testParseCSVLine_escapedQuotes() {
        let result = service.parseCSVLine("\"he said \"\"hi\"\"\",b")
        XCTAssertEqual(result, ["he said \"hi\"", "b"])
    }

    func testParseCSVLine_emptyFields() {
        let result = service.parseCSVLine(",b,,d")
        XCTAssertEqual(result, ["", "b", "", "d"])
    }

    // MARK: - Source Detection

    func testDetectSource_fuelly() {
        let headers = ["Date", "Gallons", "MPG", "Odometer", "Cost"]
        let detected = service.detectSource(headers: headers)
        XCTAssertEqual(detected, .fuelly, "Should detect Fuelly from Gallons+MPG headers")
    }

    func testDetectSource_drivvo() {
        let headers = ["Date", "Type", "Odometer", "Cost", "Notes"]
        let detected = service.detectSource(headers: headers)
        XCTAssertEqual(detected, .drivvo, "Should detect Drivvo from Type header")
    }

    func testDetectSource_simplyAuto() {
        let headers = ["Date", "Service Type", "Odometer", "Cost"]
        let detected = service.detectSource(headers: headers)
        XCTAssertEqual(detected, .simplyAuto, "Should detect Simply Auto from Service Type header")
    }

    func testDetectSource_unknown() {
        let headers = ["Col1", "Col2", "Col3"]
        let detected = service.detectSource(headers: headers)
        XCTAssertEqual(detected, .custom, "Should fall back to custom for unknown headers")
    }

    // MARK: - Column Auto-Mapping

    func testAutoMapColumns_dateColumn() {
        let headers = ["Date", "Service", "Cost"]
        let mapping = service.autoMapColumns(headers: headers, source: .custom)
        XCTAssertEqual(mapping.dateColumn, 0, "Should map date column")
    }

    func testAutoMapColumns_odometerColumn() {
        let headers = ["Date", "Odometer", "Cost"]
        let mapping = service.autoMapColumns(headers: headers, source: .custom)
        XCTAssertEqual(mapping.odometerColumn, 1, "Should map odometer column")
    }

    func testAutoMapColumns_costColumn() {
        let headers = ["Date", "Service", "Cost"]
        let mapping = service.autoMapColumns(headers: headers, source: .custom)
        XCTAssertEqual(mapping.costColumn, 2, "Should map cost column")
    }

    func testAutoMapColumns_descriptionColumn_custom() {
        let headers = ["Date", "Description", "Cost"]
        let mapping = service.autoMapColumns(headers: headers, source: .custom)
        XCTAssertEqual(mapping.descriptionColumn, 1, "Should map description column")
    }

    func testAutoMapColumns_descriptionColumn_simplyAuto() {
        let headers = ["Date", "Service Type", "Cost"]
        let mapping = service.autoMapColumns(headers: headers, source: .simplyAuto)
        XCTAssertEqual(mapping.descriptionColumn, 1, "Should map Service Type for Simply Auto")
    }

    func testAutoMapColumns_notesColumn() {
        let headers = ["Date", "Service", "Notes", "Cost"]
        let mapping = service.autoMapColumns(headers: headers, source: .custom)
        XCTAssertEqual(mapping.notesColumn, 2, "Should map notes column")
    }

    func testAutoMapColumns_mileageVariant() {
        let headers = ["Date", "Mileage", "Cost"]
        let mapping = service.autoMapColumns(headers: headers, source: .custom)
        XCTAssertEqual(mapping.odometerColumn, 1, "Should map Mileage as odometer column")
    }

    // MARK: - Date Parsing

    func testParseDate_yyyyMMdd() {
        let date = service.parseDate("2024-06-15")
        XCTAssertNotNil(date, "Should parse yyyy-MM-dd format")
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: date!), 2024)
        XCTAssertEqual(calendar.component(.month, from: date!), 6)
        XCTAssertEqual(calendar.component(.day, from: date!), 15)
    }

    func testParseDate_MMddyyyy() {
        let date = service.parseDate("06/15/2024")
        XCTAssertNotNil(date, "Should parse MM/dd/yyyy format")
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: date!), 2024)
        XCTAssertEqual(calendar.component(.month, from: date!), 6)
        XCTAssertEqual(calendar.component(.day, from: date!), 15)
    }

    func testParseDate_MMMdyyyy() {
        let date = service.parseDate("Jun 15, 2024")
        XCTAssertNotNil(date, "Should parse MMM d, yyyy format")
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: date!), 2024)
        XCTAssertEqual(calendar.component(.month, from: date!), 6)
    }

    func testParseDate_empty() {
        let date = service.parseDate("")
        XCTAssertNil(date, "Should return nil for empty string")
    }

    func testParseDate_invalid() {
        let date = service.parseDate("not a date")
        XCTAssertNil(date, "Should return nil for invalid date")
    }

    // MARK: - Service Name Normalization

    func testNormalizeServiceName_oilChange() {
        let name = service.normalizeServiceName("oil change")
        XCTAssertEqual(name, "Oil Change", "Should normalize to preset name")
    }

    func testNormalizeServiceName_oilAndFilter() {
        let name = service.normalizeServiceName("Oil & Filter")
        XCTAssertEqual(name, "Oil Change", "Should map 'Oil & Filter' to Oil Change")
    }

    func testNormalizeServiceName_brakes() {
        let name = service.normalizeServiceName("brakes")
        XCTAssertEqual(name, "Brake Inspection", "Should normalize brakes to preset name")
    }

    func testNormalizeServiceName_unknown() {
        let name = service.normalizeServiceName("Serpentine Belt")
        XCTAssertEqual(name, "Serpentine Belt", "Should keep unknown names as-is")
    }

    func testNormalizeServiceName_caseInsensitive() {
        let name = service.normalizeServiceName("TIRE ROTATION")
        XCTAssertEqual(name, "Tire Rotation", "Should be case insensitive")
    }

    func testNormalizeServiceName_sparkPlugs() {
        let name = service.normalizeServiceName("spark plug")
        XCTAssertEqual(name, "Spark Plugs", "Should normalize singular to plural preset name")
    }

    // MARK: - Full CSV Loading & Parsing

    func testLoadCSV_milesUnit() {
        let csv = "Date,Service,Odometer,Cost\n2024-06-15,Oil Change,50000,45.99"
        loadCSVString(csv)

        let result = service.parseAllRows(distanceUnit: .miles)
        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows.first?.odometer, 50000, "Miles should pass through unchanged")
    }

    func testLoadCSV_kilometersUnit() {
        let csv = "Date,Service,Odometer,Cost\n2024-06-15,Oil Change,80000,45.99"
        loadCSVString(csv)

        let result = service.parseAllRows(distanceUnit: .kilometers)
        XCTAssertEqual(result.rows.count, 1)
        let expectedMiles = DistanceUnit.kilometers.toMiles(80000)
        XCTAssertEqual(result.rows.first?.odometer, expectedMiles, "Should convert km to miles")
    }

    // MARK: - Service Grouping

    func testLoadCSV_groupsByServiceName() {
        let csv = """
Date,Service,Odometer,Cost
2024-01-15,Oil Change,50000,45
2024-04-15,Tire Rotation,52000,35
2024-07-15,Oil Change,55000,48
2024-10-15,Oil Change,58000,46
"""
        loadCSVString(csv)

        let result = service.parseAllRows(distanceUnit: .miles)
        XCTAssertEqual(result.rows.count, 4)

        let grouped = Dictionary(grouping: result.rows, by: { $0.serviceName })
        XCTAssertEqual(grouped["Oil Change"]?.count, 3, "Should have 3 oil change logs")
        XCTAssertEqual(grouped["Tire Rotation"]?.count, 1, "Should have 1 tire rotation log")
    }

    // MARK: - Cost Parsing

    func testLoadCSV_costWithDollarSign() {
        let csv = "Date,Service,Cost\n2024-01-15,Oil Change,$45.99"
        loadCSVString(csv)

        let result = service.parseAllRows(distanceUnit: .miles)
        XCTAssertEqual(result.rows.first?.cost, Decimal(string: "45.99"), "Should parse cost with dollar sign")
    }

    func testLoadCSV_costWithComma() {
        let csv = "Date,Service,Cost\n2024-01-15,Brake Pads,\"1,285.50\""
        loadCSVString(csv)

        let result = service.parseAllRows(distanceUnit: .miles)
        XCTAssertEqual(result.rows.first?.cost, Decimal(string: "1285.50"), "Should parse cost with comma separator")
    }

    // MARK: - Warnings

    func testLoadCSV_warningForMissingServiceName() {
        let csv = "Date,Service,Cost\n2024-01-15,,45\n2024-02-15,Oil Change,48"
        loadCSVString(csv)

        let result = service.parseAllRows(distanceUnit: .miles)
        XCTAssertEqual(result.rows.count, 1, "Should skip row with empty service name")
        XCTAssertEqual(result.warnings.count, 1, "Should have 1 warning for missing name")
    }

    func testLoadCSV_warningForUnparsableDate() {
        let csv = "Date,Service,Cost\nnot-a-date,Oil Change,45"
        loadCSVString(csv)

        let result = service.parseAllRows(distanceUnit: .miles)
        XCTAssertEqual(result.rows.count, 1, "Should still create row even with bad date")
        XCTAssertNil(result.rows.first?.date, "Date should be nil for unparsable date")
        XCTAssertEqual(result.warnings.count, 1, "Should warn about unparsable date")
    }

    // MARK: - Commit to SwiftData

    func testCommitImport_createsServicesAndLogs() {
        let vehicle = Vehicle(name: "Test Car", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let parsedRows = [
            CSVParsedRow(date: makeDate(2024, 1, 15), odometer: 50000, serviceName: "Oil Change", cost: 45, notes: nil, rawRow: 2),
            CSVParsedRow(date: makeDate(2024, 4, 15), odometer: 52000, serviceName: "Tire Rotation", cost: 35, notes: nil, rawRow: 3),
            CSVParsedRow(date: makeDate(2024, 7, 15), odometer: 55000, serviceName: "Oil Change", cost: 48, notes: "Synthetic", rawRow: 4),
        ]

        let preview = CSVImportPreview(
            serviceCount: 2,
            logCount: 3,
            totalCost: 128,
            serviceNames: ["Oil Change", "Tire Rotation"],
            warnings: [],
            parsedRows: parsedRows
        )

        let result = service.commitImport(to: vehicle, preview: preview, modelContext: modelContext)

        XCTAssertEqual(result.servicesCreated, 2, "Should create 2 services")
        XCTAssertEqual(result.logsCreated, 3, "Should create 3 logs")
        XCTAssertEqual(result.totalCost, 128)
    }

    func testCommitImport_setsLastPerformedToMostRecent() {
        let vehicle = Vehicle(name: "Test Car", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let olderDate = makeDate(2024, 1, 15)
        let newerDate = makeDate(2024, 7, 15)

        let parsedRows = [
            CSVParsedRow(date: olderDate, odometer: 50000, serviceName: "Oil Change", cost: 45, notes: nil, rawRow: 2),
            CSVParsedRow(date: newerDate, odometer: 55000, serviceName: "Oil Change", cost: 48, notes: nil, rawRow: 3),
        ]

        let preview = CSVImportPreview(
            serviceCount: 1,
            logCount: 2,
            totalCost: 93,
            serviceNames: ["Oil Change"],
            warnings: [],
            parsedRows: parsedRows
        )

        _ = service.commitImport(to: vehicle, preview: preview, modelContext: modelContext)

        let descriptor = FetchDescriptor<Service>(predicate: #Predicate { $0.name == "Oil Change" })
        let services = try? modelContext.fetch(descriptor)

        XCTAssertEqual(services?.count, 1)
        XCTAssertEqual(services?.first?.lastPerformed, newerDate, "Should set lastPerformed to most recent log date")
        XCTAssertEqual(services?.first?.lastMileage, 55000, "Should set lastMileage to most recent log mileage")
    }

    func testCommitImport_setsLogsToMaintenanceCategory() {
        let vehicle = Vehicle(name: "Test Car", make: "Test", model: "Model", year: 2020, currentMileage: 50000)
        modelContext.insert(vehicle)

        let parsedRows = [
            CSVParsedRow(date: makeDate(2024, 1, 15), odometer: 50000, serviceName: "Oil Change", cost: 45, notes: nil, rawRow: 2),
        ]

        let preview = CSVImportPreview(
            serviceCount: 1,
            logCount: 1,
            totalCost: 45,
            serviceNames: ["Oil Change"],
            warnings: [],
            parsedRows: parsedRows
        )

        _ = service.commitImport(to: vehicle, preview: preview, modelContext: modelContext)

        let descriptor = FetchDescriptor<ServiceLog>()
        let logs = try? modelContext.fetch(descriptor)

        XCTAssertEqual(logs?.count, 1)
        XCTAssertEqual(logs?.first?.costCategory, .maintenance, "Imported logs should have maintenance category")
    }

    // MARK: - Full Format Tests

    func testFuellyFormat_detection() {
        let headers = ["Date", "Gallons", "MPG", "Odometer", "Cost per Gallon", "Cost", "Notes"]
        let detected = service.detectSource(headers: headers)
        XCTAssertEqual(detected, .fuelly)
    }

    func testDrivvoFormat_detection() {
        let headers = ["Date", "Type", "Description", "Odometer", "Cost", "Notes"]
        let detected = service.detectSource(headers: headers)
        XCTAssertEqual(detected, .drivvo)
    }

    func testSimplyAutoFormat_detection() {
        let headers = ["Date", "Service Type", "Odometer", "Cost", "Notes"]
        let detected = service.detectSource(headers: headers)
        XCTAssertEqual(detected, .simplyAuto)
    }

    // MARK: - Generate Preview

    func testGeneratePreview_producesCorrectCounts() {
        let csv = """
Date,Service,Odometer,Cost
2024-01-15,Oil Change,50000,45
2024-04-15,Tire Rotation,52000,35
2024-07-15,Oil Change,55000,48
"""
        loadCSVString(csv)

        let preview = service.generatePreview(distanceUnit: .miles)
        XCTAssertEqual(preview.serviceCount, 2, "Should have 2 unique services")
        XCTAssertEqual(preview.logCount, 3, "Should have 3 total logs")
        XCTAssertEqual(preview.totalCost, 128, "Should sum total cost")
    }

    // MARK: - Load CSV File

    func testLoadCSV_setsHeaders() {
        let csv = "Date,Service,Odometer,Cost\n2024-01-15,Oil Change,50000,45"
        loadCSVString(csv)

        XCTAssertEqual(service.headers, ["Date", "Service", "Odometer", "Cost"])
    }

    func testLoadCSV_setsPreviewRows() {
        let csv = """
Date,Service,Cost
2024-01-15,Oil Change,45
2024-02-15,Tire Rotation,35
2024-03-15,Brake Pads,200
2024-04-15,Air Filter,25
"""
        loadCSVString(csv)

        XCTAssertEqual(service.previewRows.count, 3, "Should have max 3 preview rows")
    }

    func testLoadCSV_autoDetectsSource() {
        let csv = "Date,Gallons,MPG,Odometer,Cost\n2024-01-15,12.5,28.4,50000,45"
        loadCSVString(csv)

        XCTAssertEqual(service.detectedSource, .fuelly, "Should auto-detect Fuelly format")
    }

    // MARK: - Helpers

    private func loadCSVString(_ csv: String) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_import_\(UUID().uuidString).csv")
        try! csv.write(to: tempURL, atomically: true, encoding: .utf8)
        try! service.loadCSV(from: tempURL)
        try? FileManager.default.removeItem(at: tempURL)
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
