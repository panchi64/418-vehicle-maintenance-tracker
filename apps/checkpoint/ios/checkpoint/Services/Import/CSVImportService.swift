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

nonisolated enum CSVImportSource: String, CaseIterable, Identifiable, Sendable {
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

nonisolated struct CSVColumnMapping: Sendable {
    var dateColumn: Int?
    var odometerColumn: Int?
    var descriptionColumn: Int?
    var costColumn: Int?
    var notesColumn: Int?
}

// MARK: - Import Warning

nonisolated struct CSVImportWarning: Identifiable, Sendable {
    let id = UUID()
    let row: Int
    let message: String
}

// MARK: - Parsed Row

nonisolated struct CSVParsedRow: Sendable {
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

nonisolated enum CSVImportError: Error, LocalizedError {
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

    private let logger = Logger(category: "CSVImport")

    // MARK: - State

    var headers: [String] = []
    var previewRows: [[String]] = []
    var detectedSource: CSVImportSource = .custom
    var columnMapping = CSVColumnMapping()
    var importPreview: CSVImportPreview?

    private var allRows: [[String]] = []

    private init() {}

    // MARK: - Known Service Names (for preset matching)

    private nonisolated static let presetNameMap: [String: String] = [
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

    // MARK: - Date Parsing
    //
    // Slash-delimited dates are ambiguous: "03/04/2024" is Mar 4 (US, month-first)
    // or Apr 3 (EU, day-first). We resolve the order once per import by scanning the
    // whole date column — a row whose first field is > 12 proves day-first, one whose
    // second field is > 12 proves month-first. When every row is ambiguous we fall
    // back to the user's locale ordering. See `inferSlashDateOrder`.

    nonisolated enum SlashDateOrder: Sendable, Equatable {
        case monthFirst
        case dayFirst
    }

    // MARK: - Public API

    /// Load and parse a CSV file from a URL.
    ///
    /// File reading and line parsing run off the main actor (via a detached task)
    /// so a large import doesn't block the UI; the parsed result is then published
    /// to this observable's `@MainActor` state.
    func loadCSV(from url: URL) async throws {
        reset()

        let loaded: LoadedCSV
        do {
            loaded = try await Task.detached { [self] in
                try readAndParse(from: url)
            }.value
        } catch {
            logger.error("Failed to read CSV file: \(error.localizedDescription)")
            throw error
        }

        headers = loaded.headers
        allRows = loaded.allRows
        previewRows = loaded.previewRows
        detectedSource = loaded.detectedSource
        columnMapping = loaded.columnMapping

        logger.info("CSV loaded: \(loaded.headers.count) columns, \(loaded.allRows.count) data rows, detected: \(loaded.detectedSource.rawValue)")
    }

    /// Generate an import preview based on current column mapping.
    ///
    /// Row parsing (the expensive pass over every data row) runs off the main actor.
    func generatePreview(distanceUnit: DistanceUnit) async -> CSVImportPreview {
        let rowsSnapshot = allRows
        let mapping = columnMapping
        let milesScale = Self.milesScale(for: distanceUnit)

        let parsed = await Task.detached { [self] in
            parseRows(rowsSnapshot, columnMapping: mapping, milesScale: milesScale)
        }.value

        // Group by service name
        let grouped = Dictionary(grouping: parsed.rows, by: { $0.serviceName })
        let serviceNames = grouped.keys.sorted()

        let totalCost = parsed.rows.compactMap { $0.cost }.reduce(Decimal.zero, +)

        let preview = CSVImportPreview(
            serviceCount: serviceNames.count,
            logCount: parsed.rows.count,
            totalCost: totalCost,
            serviceNames: serviceNames,
            warnings: parsed.warnings,
            parsedRows: parsed.rows
        )

        importPreview = preview
        return preview
    }

    // MARK: - Off-Main File Reading

    /// Sendable payload carrying a fully-parsed CSV back to the main actor.
    private nonisolated struct LoadedCSV: Sendable {
        let headers: [String]
        let allRows: [[String]]
        let previewRows: [[String]]
        let detectedSource: CSVImportSource
        let columnMapping: CSVColumnMapping
    }

    /// Reads the file, decodes it (with an encoding fallback chain), and parses the
    /// header + rows. Runs off the main actor — touches no `@MainActor` state.
    private nonisolated func readAndParse(from url: URL) throws -> LoadedCSV {
        let didAccessSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CSVImportError.fileReadFailed
        }

        guard let content = Self.decodeCSVData(data) else {
            throw CSVImportError.fileReadFailed
        }

        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !lines.isEmpty else { throw CSVImportError.emptyFile }

        let parsedLines = lines.map { parseCSVLine($0) }

        guard let headerRow = parsedLines.first else { throw CSVImportError.noHeaderRow }
        let headers = headerRow.map { $0.trimmingCharacters(in: .whitespaces) }

        let dataRows = Array(parsedLines.dropFirst())
        guard !dataRows.isEmpty else { throw CSVImportError.noDataRows }

        let detectedSource = detectSource(headers: headers)
        let columnMapping = autoMapColumns(headers: headers, source: detectedSource)

        return LoadedCSV(
            headers: headers,
            allRows: dataRows,
            previewRows: Array(dataRows.prefix(3)),
            detectedSource: detectedSource,
            columnMapping: columnMapping
        )
    }

    /// Decodes raw CSV bytes, honoring a byte-order mark and falling back across
    /// common encodings (UTF-8 → UTF-16 → Latin-1) before giving up.
    nonisolated static func decodeCSVData(_ data: Data) -> String? {
        let decoded: String?
        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
            // UTF-16 with BOM — its interior null bytes would let .utf8 "succeed"
            // with garbled text, so honor the BOM first.
            decoded = String(data: data, encoding: .utf16)
        } else if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            decoded = String(data: data.dropFirst(3), encoding: .utf8)
        } else if let utf8 = String(data: data, encoding: .utf8) {
            decoded = utf8
        } else if data.contains(0), let utf16 = String(data: data, encoding: .utf16) {
            // BOM-less UTF-16 text contains NUL bytes (the high byte of ASCII
            // code units); Latin-1/UTF-8 text never does. Without this gate,
            // .utf16 happily decodes Latin-1 bytes into CJK garbage.
            decoded = utf16
        } else {
            // Latin-1 maps every byte, so this last resort never fails.
            decoded = String(data: data, encoding: .isoLatin1)
        }

        // Strip any residual BOM so it can't corrupt the first header cell.
        guard let result = decoded else { return nil }
        return result.hasPrefix("\u{FEFF}") ? String(result.dropFirst()) : result
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

    nonisolated func detectSource(headers: [String]) -> CSVImportSource {
        let headerSet = Set(headers)

        for source in CSVImportSource.allCases where source != .custom {
            if source.signatureHeaders.isSubset(of: headerSet) {
                return source
            }
        }

        return .custom
    }

    // MARK: - Column Auto-Mapping

    nonisolated func autoMapColumns(headers: [String], source: CSVImportSource) -> CSVColumnMapping {
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

    /// Parses `allRows` using the current column mapping. Kept as a thin main-actor
    /// wrapper so existing callers and tests can invoke it synchronously; the work
    /// itself is nonisolated and moved off-main by `generatePreview`.
    func parseAllRows(distanceUnit: DistanceUnit) -> (rows: [CSVParsedRow], warnings: [CSVImportWarning]) {
        parseRows(allRows, columnMapping: columnMapping, milesScale: Self.milesScale(for: distanceUnit))
    }

    /// The factor that converts a value in `unit` to miles. Resolved on the main
    /// actor (where `DistanceUnit` is isolated) so the nonisolated parser only needs
    /// a plain `Double`.
    static func milesScale(for unit: DistanceUnit) -> Double {
        unit == .miles ? 1.0 : DistanceUnit.milesPerKm
    }

    /// Pure, off-main row parser. Locks the ambiguous slash-date order once for the
    /// whole import before parsing individual rows. `milesScale` converts the
    /// odometer column into miles (see `milesScale(for:)`).
    nonisolated func parseRows(
        _ allRows: [[String]],
        columnMapping: CSVColumnMapping,
        milesScale: Double
    ) -> (rows: [CSVParsedRow], warnings: [CSVImportWarning]) {
        var rows: [CSVParsedRow] = []
        var warnings: [CSVImportWarning] = []

        // Decide month-first vs day-first once, from the full date column.
        let slashOrder: SlashDateOrder = {
            guard let col = columnMapping.dateColumn else { return .monthFirst }
            let dateStrings = allRows.compactMap { row in col < row.count ? row[col] : nil }
            return inferSlashDateOrder(from: dateStrings)
        }()

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
                date = parseDate(raw, slashOrder: slashOrder)
                if date == nil && !raw.isEmpty {
                    warnings.append(CSVImportWarning(row: rowNumber, message: "Row \(rowNumber): Could not parse date '\(raw)'"))
                }
            }

            // Parse odometer (convert from user's unit to miles for storage).
            // Matches DistanceUnit.toMiles: multiply by the scale, then round.
            var odometer: Int?
            if let col = columnMapping.odometerColumn, col < row.count {
                let raw = row[col].trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: " ", with: "")
                if let value = Int(raw) {
                    odometer = Int((Double(value) * milesScale).rounded())
                } else if let value = Double(raw) {
                    odometer = Int((Double(Int(value)) * milesScale).rounded())
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

    /// Single-string date parse. Resolves ambiguous slash dates from the string
    /// itself when it's unambiguous, otherwise from the current locale.
    nonisolated func parseDate(_ string: String) -> Date? {
        parseDate(string, slashOrder: inferSlashDateOrder(from: [string]))
    }

    /// Parses a date string, using `slashOrder` to disambiguate `n/n/yyyy` values.
    nonisolated func parseDate(_ string: String, slashOrder: SlashDateOrder) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Unambiguous formats first (year-first and month-name never collide).
        let unambiguous = [
            Formatters.dateParserDashYMD,
            Formatters.dateParserSlashYMD,
            Formatters.dateParserMediumDate,
        ]
        for formatter in unambiguous {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        // Ambiguous slash dates use the order locked in for this import.
        let slashParsers = slashOrder == .dayFirst
            ? [Formatters.dateParserSlashDMY, Formatters.dateParserSlashDMYShort]
            : [Formatters.dateParserSlashMDY, Formatters.dateParserSlashMDYShort]
        for formatter in slashParsers {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        return iso.date(from: trimmed)
    }

    /// Determines whether a set of slash-delimited dates is month-first or day-first.
    /// A single unambiguous row (a field > 12) locks the order for the whole import;
    /// if every candidate is ambiguous, falls back to the user's locale ordering.
    nonisolated func inferSlashDateOrder(from dateStrings: [String], locale: Locale = .current) -> SlashDateOrder {
        var sawDayFirst = false    // first field > 12  ⇒ dd/MM
        var sawMonthFirst = false  // second field > 12 ⇒ MM/dd

        for raw in dateStrings {
            let parts = raw.trimmingCharacters(in: .whitespaces).split(separator: "/")
            // Only consider d/M/yyyy-shaped values; skip yyyy/MM/dd and other formats.
            guard parts.count == 3,
                  parts[0].count <= 2, parts[1].count <= 2, parts[2].count == 4,
                  let first = Int(parts[0]), let second = Int(parts[1]) else { continue }

            if first > 12 && second <= 12 {
                sawDayFirst = true
            } else if second > 12 && first <= 12 {
                sawMonthFirst = true
            }
        }

        if sawDayFirst && !sawMonthFirst { return .dayFirst }
        if sawMonthFirst && !sawDayFirst { return .monthFirst }
        return Self.localePrefersDayFirst(locale) ? .dayFirst : .monthFirst
    }

    /// Whether the locale writes day before month in a numeric date (e.g. en_GB).
    nonisolated static func localePrefersDayFirst(_ locale: Locale) -> Bool {
        guard let template = DateFormatter.dateFormat(fromTemplate: "yMd", options: 0, locale: locale),
              let dayIndex = template.firstIndex(of: "d"),
              let monthIndex = template.firstIndex(of: "M") else {
            return false
        }
        return dayIndex < monthIndex
    }

    // MARK: - Service Name Normalization

    nonisolated func normalizeServiceName(_ raw: String) -> String {
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

    nonisolated func parseCSVLine(_ line: String) -> [String] {
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
