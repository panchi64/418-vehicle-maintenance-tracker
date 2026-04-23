//
//  CSVImportService.swift
//  checkpoint
//
//  CSV import service supporting Fuelly, Drivvo, and Simply Auto formats.
//  Parses CSV files, auto-detects source format, and imports service history.
//

import Foundation
import SwiftData
import os

// MARK: - Import Source

enum CSVImportSource: String, CaseIterable, Identifiable {
    case fuelly = "Fuelly"
    case drivvo = "Drivvo"
    case simplyAuto = "Simply Auto"
    case custom = "Custom"

    var id: String { rawValue }

    var signatureHeaders: Set<String> {
        switch self {
        case .fuelly: return ["Gallons", "MPG"]
        case .drivvo: return ["Type"]
        case .simplyAuto: return ["Service Type"]
        case .custom: return []
        }
    }
}

// MARK: - Column Mapping

struct CSVColumnMapping {
    var dateColumn: Int?
    var odometerColumn: Int?
    var descriptionColumn: Int?
    var costColumn: Int?
    var notesColumn: Int?
}

// MARK: - Import Warning

struct CSVImportWarning: Identifiable {
    let id = UUID()
    let row: Int
    let message: String
}

// MARK: - Parsed Row

struct CSVParsedRow {
    let date: Date?
    let odometer: Int?
    let serviceName: String
    let cost: Decimal?
    let notes: String?
    let rawRow: Int
}

// MARK: - Import Preview

struct CSVImportPreview {
    let serviceCount: Int
    let logCount: Int
    let totalCost: Decimal
    let serviceNames: [String]
    let warnings: [CSVImportWarning]
    let parsedRows: [CSVParsedRow]
}

// MARK: - Import Result

struct CSVImportResult {
    let servicesCreated: Int
    let logsCreated: Int
    let totalCost: Decimal
}

// MARK: - Import Error

enum CSVImportError: Error, LocalizedError {
    case fileReadFailed
    case emptyFile
    case noHeaderRow
    case noDataRows
    case noDateColumn
    case noDescriptionColumn
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .fileReadFailed: return "Could not read the CSV file."
        case .emptyFile: return "The file is empty."
        case .noHeaderRow: return "No header row found."
        case .noDataRows: return "No data rows found."
        case .noDateColumn: return "Could not identify a date column."
        case .noDescriptionColumn: return "Could not identify a description column."
        case .invalidFormat: return "The file format is not recognized."
        }
    }
}

// MARK: - CSV Import Service

@Observable
@MainActor
final class CSVImportService {
    static let shared = CSVImportService()

    private let logger = Logger(subsystem: "com.418-studio.checkpoint", category: "CSVImport")

    // MARK: - State

    var headers: [String] = []
    var previewRows: [[String]] = []
    var detectedSource: CSVImportSource = .custom
    var columnMapping = CSVColumnMapping()
    var importPreview: CSVImportPreview?

    private var allRows: [[String]] = []

    private init() {}

    // MARK: - Known Service Names (for preset matching)

    private static let presetNameMap: [String: String] = [
        "oil change": "Oil Change",
        "oil & filter": "Oil Change",
        "oil filter": "Oil Change",
        "engine oil": "Oil Change",
        "tire rotation": "Tire Rotation",
        "rotate tires": "Tire Rotation",
        "brake inspection": "Brake Inspection",
        "brake check": "Brake Inspection",
        "brake pads": "Brake Inspection",
        "brakes": "Brake Inspection",
        "air filter": "Air Filter",
        "engine air filter": "Air Filter",
        "cabin air filter": "Cabin Air Filter",
        "cabin filter": "Cabin Air Filter",
        "transmission fluid": "Transmission Fluid",
        "trans fluid": "Transmission Fluid",
        "transmission": "Transmission Fluid",
        "coolant flush": "Coolant Flush",
        "coolant": "Coolant Flush",
        "antifreeze": "Coolant Flush",
        "spark plugs": "Spark Plugs",
        "spark plug": "Spark Plugs",
        "battery check": "Battery Check",
        "battery": "Battery Check",
        "battery replacement": "Battery Check",
        "wiper blades": "Wiper Blades",
        "wipers": "Wiper Blades",
    ]

    // MARK: - Date Formats

    private static let dateFormats: [String] = [
        "yyyy-MM-dd",
        "MM/dd/yyyy",
        "dd/MM/yyyy",
        "MMM d, yyyy",
        "M/d/yyyy",
        "d/M/yyyy",
        "yyyy/MM/dd",
    ]

    // MARK: - Public API

    /// Load and parse a CSV file from a URL
    func loadCSV(from url: URL) throws {
        reset()

        let didAccessSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            logger.error("Failed to read CSV file: \(error.localizedDescription)")
            throw CSVImportError.fileReadFailed
        }

        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !lines.isEmpty else { throw CSVImportError.emptyFile }

        let parsedLines = lines.map { parseCSVLine($0) }

        guard let headerRow = parsedLines.first else { throw CSVImportError.noHeaderRow }
        headers = headerRow.map { $0.trimmingCharacters(in: .whitespaces) }

        let dataRows = Array(parsedLines.dropFirst())
        guard !dataRows.isEmpty else { throw CSVImportError.noDataRows }

        allRows = dataRows
        previewRows = Array(dataRows.prefix(3))

        // Auto-detect source
        detectedSource = detectSource(headers: headers)

        // Auto-map columns
        columnMapping = autoMapColumns(headers: headers, source: detectedSource)

        logger.info("CSV loaded: \(self.headers.count) columns, \(dataRows.count) data rows, detected: \(self.detectedSource.rawValue)")
    }

    /// Generate an import preview based on current column mapping
    func generatePreview(distanceUnit: DistanceUnit) -> CSVImportPreview {
        let parsed = parseAllRows(distanceUnit: distanceUnit)
        let warnings = parsed.warnings
        let rows = parsed.rows

        // Group by service name
        let grouped = Dictionary(grouping: rows, by: { $0.serviceName })
        let serviceNames = grouped.keys.sorted()

        let totalCost = rows.compactMap { $0.cost }.reduce(Decimal.zero, +)

        let preview = CSVImportPreview(
            serviceCount: serviceNames.count,
            logCount: rows.count,
            totalCost: totalCost,
            serviceNames: serviceNames,
            warnings: warnings,
            parsedRows: rows
        )

        importPreview = preview
        return preview
    }

    /// Commit the import to SwiftData
    func commitImport(
        to vehicle: Vehicle,
        preview: CSVImportPreview,
        modelContext: ModelContext
    ) -> CSVImportResult {
        let grouped = Dictionary(grouping: preview.parsedRows, by: { $0.serviceName })

        var servicesCreated = 0
        var logsCreated = 0

        for (serviceName, rows) in grouped {
            // Create Service
            let service = Service(name: serviceName)
            service.vehicle = vehicle

            // Find most recent log to set lastPerformed
            let sortedRows = rows.sorted { r1, r2 in
                guard let d1 = r1.date, let d2 = r2.date else { return false }
                return d1 > d2
            }

            if let mostRecent = sortedRows.first {
                service.lastPerformed = mostRecent.date
                service.lastMileage = mostRecent.odometer
            }

            modelContext.insert(service)
            servicesCreated += 1

            // Create ServiceLogs
            for row in rows {
                let log = ServiceLog(
                    service: service,
                    vehicle: vehicle,
                    performedDate: row.date ?? .now,
                    mileageAtService: row.odometer ?? 0,
                    cost: row.cost,
                    costCategory: .maintenance,
                    notes: row.notes
                )
                modelContext.insert(log)
                logsCreated += 1
            }
        }

        do {
            try modelContext.save()
            logger.info("Import committed: \(servicesCreated) services, \(logsCreated) logs")
        } catch {
            logger.error("Failed to save import: \(error.localizedDescription)")
        }

        return CSVImportResult(
            servicesCreated: servicesCreated,
            logsCreated: logsCreated,
            totalCost: preview.totalCost
        )
    }

    /// Reset all state
    func reset() {
        headers = []
        previewRows = []
        allRows = []
        detectedSource = .custom
        columnMapping = CSVColumnMapping()
        importPreview = nil
    }

    // MARK: - Source Detection

    func detectSource(headers: [String]) -> CSVImportSource {
        let headerSet = Set(headers)

        for source in CSVImportSource.allCases where source != .custom {
            if source.signatureHeaders.isSubset(of: headerSet) {
                return source
            }
        }

        return .custom
    }

    // MARK: - Column Auto-Mapping

    func autoMapColumns(headers: [String], source: CSVImportSource) -> CSVColumnMapping {
        var mapping = CSVColumnMapping()
        let lowered = headers.map { $0.lowercased() }

        // Date column
        mapping.dateColumn = lowered.firstIndex { name in
            name.contains("date") || name == "day"
        }

        // Odometer column
        mapping.odometerColumn = lowered.firstIndex { name in
            name.contains("odometer") || name.contains("odo") || name.contains("mileage") || name.contains("km")
        }

        // Description column - source-specific
        switch source {
        case .fuelly:
            // Fuelly uses "Notes" or "Service" for description
            mapping.descriptionColumn = lowered.firstIndex { name in
                name == "service" || name == "description"
            } ?? lowered.firstIndex { name in
                name == "notes"
            }
        case .drivvo:
            mapping.descriptionColumn = lowered.firstIndex { name in
                name == "description" || name == "service" || name == "type"
            }
        case .simplyAuto:
            mapping.descriptionColumn = lowered.firstIndex { name in
                name.contains("service type") || name == "description" || name == "service"
            }
        case .custom:
            mapping.descriptionColumn = lowered.firstIndex { name in
                name.contains("description") || name.contains("service") || name.contains("type") || name.contains("name")
            }
        }

        // Cost column
        mapping.costColumn = lowered.firstIndex { name in
            name.contains("cost") || name.contains("price") || name.contains("total") || name.contains("amount")
        }

        // Notes column
        mapping.notesColumn = lowered.firstIndex { name in
            name == "notes" || name == "note" || name == "comment" || name == "comments" || name == "memo"
        }

        // Avoid mapping notes to the same column as description
        if mapping.notesColumn == mapping.descriptionColumn {
            mapping.notesColumn = nil
        }

        return mapping
    }

    // MARK: - Row Parsing

    func parseAllRows(distanceUnit: DistanceUnit) -> (rows: [CSVParsedRow], warnings: [CSVImportWarning]) {
        var rows: [CSVParsedRow] = []
        var warnings: [CSVImportWarning] = []

        for (index, row) in allRows.enumerated() {
            let rowNumber = index + 2 // 1-based, +1 for header

            // Get service name
            var serviceName: String?
            if let col = columnMapping.descriptionColumn, col < row.count {
                let raw = row[col].trimmingCharacters(in: .whitespaces)
                if !raw.isEmpty {
                    serviceName = normalizeServiceName(raw)
                }
            }

            guard let name = serviceName, !name.isEmpty else {
                warnings.append(CSVImportWarning(row: rowNumber, message: "Row \(rowNumber): Missing service name, skipped"))
                continue
            }

            // Parse date
            var date: Date?
            if let col = columnMapping.dateColumn, col < row.count {
                let raw = row[col].trimmingCharacters(in: .whitespaces)
                date = parseDate(raw)
                if date == nil && !raw.isEmpty {
                    warnings.append(CSVImportWarning(row: rowNumber, message: "Row \(rowNumber): Could not parse date '\(raw)'"))
                }
            }

            // Parse odometer (convert from user's unit to miles for storage)
            var odometer: Int?
            if let col = columnMapping.odometerColumn, col < row.count {
                let raw = row[col].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: " ", with: "")
                if let value = Int(raw) {
                    odometer = distanceUnit.toMiles(value)
                } else if let value = Double(raw) {
                    odometer = distanceUnit.toMiles(Int(value))
                }
            }

            // Parse cost
            var cost: Decimal?
            if let col = columnMapping.costColumn, col < row.count {
                let raw = row[col].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: " ", with: "")
                if let value = Decimal(string: raw), value > 0 {
                    cost = value
                }
            }

            // Parse notes
            var notes: String?
            if let col = columnMapping.notesColumn, col < row.count {
                let raw = row[col].trimmingCharacters(in: .whitespaces)
                if !raw.isEmpty {
                    notes = raw
                }
            }

            rows.append(CSVParsedRow(
                date: date,
                odometer: odometer,
                serviceName: name,
                cost: cost,
                notes: notes,
                rawRow: rowNumber
            ))
        }

        return (rows, warnings)
    }

    // MARK: - Date Parsing

    func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in Self.dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        // Try ISO8601 as fallback
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        return iso.date(from: trimmed)
    }

    // MARK: - Service Name Normalization

    func normalizeServiceName(_ raw: String) -> String {
        let lowered = raw.lowercased().trimmingCharacters(in: .whitespaces)

        // Try exact match against preset names
        if let presetName = Self.presetNameMap[lowered] {
            return presetName
        }

        // Try substring match
        for (key, value) in Self.presetNameMap {
            if lowered.contains(key) {
                return value
            }
        }

        // Return original with title case
        return raw.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - CSV Line Parsing

    func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()

        while let char = iterator.next() {
            if inQuotes {
                if char == "\"" {
                    // Check for escaped quote
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else {
                            inQuotes = false
                            if next == "," {
                                fields.append(current)
                                current = ""
                            } else {
                                current.append(next)
                            }
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
        }

        fields.append(current)
        return fields
    }
}
