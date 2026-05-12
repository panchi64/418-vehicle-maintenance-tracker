//
//  NHTSAService.swift
//  checkpoint
//
//  NHTSA API integration for VIN decoding and recall alerts
//  Uses free, no-auth NHTSA APIs (vPIC for VIN, recalls API for safety recalls)
//

@preconcurrency import Foundation

// MARK: - Error Types

enum NHTSAError: LocalizedError {
    case invalidVIN
    case networkUnavailable
    case serverError
    case decodingFailed
    case noResultsFound
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidVIN:
            return "Invalid VIN. Must be 17 alphanumeric characters (no I, O, or Q)."
        case .networkUnavailable:
            return "No internet connection. Check your connection and try again."
        case .serverError:
            return "NHTSA service unavailable. Try again later."
        case .decodingFailed:
            return "Unexpected response. Try again later."
        case .noResultsFound:
            return "Could not decode this VIN. You can enter details manually."
        case .timeout:
            return "Request timed out. Try again."
        }
    }
}

// MARK: - Response Models

struct VINDecodeResult: Sendable {
    let make: String
    let model: String
    let modelYear: Int?
    let engineDescription: String
    let driveType: String
    let bodyClass: String
    let fuelType: String
    let errorCode: String
}

struct RecallInfo: Identifiable, Codable, Sendable {
    let campaignNumber: String
    let component: String
    let summary: String
    let consequence: String
    let remedy: String
    let reportDate: String
    let parkIt: Bool
    let parkOutside: Bool

    var id: String { campaignNumber }

    /// NHTSA's API mixes `MM/dd/yyyy` and `dd/MM/yyyy` — disambiguate by the first component
    /// (>12 ⇒ day-first); when both halves are ≤12 we default to US `MM/dd/yyyy`.
    var reportDateParsed: Date? {
        let parts = reportDate.split(separator: "/")
        guard parts.count == 3, let first = Int(parts[0]) else { return nil }
        let formatter = first > 12 ? Formatters.dateParserSlashDMY : Formatters.dateParserSlashMDY
        return formatter.date(from: reportDate)
    }
}

extension Array where Element == RecallInfo {
    func sortedNewestFirst() -> [RecallInfo] {
        sorted { lhs, rhs in
            (lhs.reportDateParsed ?? .distantPast) > (rhs.reportDateParsed ?? .distantPast)
        }
    }
}

// MARK: - API Response Decodables
// Note: These DTOs are marked nonisolated to opt out of the project's default @MainActor
// isolation, allowing them to be decoded within the NHTSAService actor.

private nonisolated struct VINDecodeResponse: Decodable, Sendable {
    let Results: [VINDecodeResultJSON]
}

private nonisolated struct VINDecodeResultJSON: Decodable, Sendable {
    let Make: String?
    let Model: String?
    let ModelYear: String?
    let EngineModel: String?
    let DisplacementL: String?
    let FuelTypePrimary: String?
    let DriveType: String?
    let BodyClass: String?
    let ErrorCode: String?
    let EngineCylinders: String?
    let EngineHP: String?
}

private nonisolated struct RecallsResponse: Decodable, Sendable {
    let Count: Int
    let results: [RecallResultJSON]
}

private nonisolated struct RecallResultJSON: Decodable, Sendable {
    let NHTSACampaignNumber: String?
    let Component: String?
    let Summary: String?
    let Consequence: String?
    let Remedy: String?
    let ReportReceivedDate: String?
    let parkIt: Bool?
    let parkOutSide: Bool?
}

// MARK: - JSON Decoding Helper

/// Nonisolated JSON decoding to avoid Swift 6 actor isolation warnings
/// Must be at file scope (not inside actor) to properly break isolation
private nonisolated func decodeNHTSAJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try JSONDecoder().decode(type, from: data)
}

// MARK: - Cache Entry

nonisolated struct CacheEntry<T: Sendable>: Sendable {
    let data: T
    let timestamp: Date

    func isValid(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) < ttl
    }
}

extension CacheEntry: Codable where T: Codable {}

// MARK: - Service

actor NHTSAService {
    static let shared = NHTSAService()

    private let session: URLSession

    // Cache storage
    private var vinCache: [String: CacheEntry<VINDecodeResult>] = [:]
    private var recallsCache: [String: CacheEntry<[RecallInfo]>] = [:]

    // Cache TTLs
    private let vinCacheTTL: TimeInterval = 24 * 60 * 60  // 24 hours (VIN data is static)
    private let recallsCacheTTL: TimeInterval = 60 * 60   // 1 hour (recalls can be updated)

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Clears all cached data (useful for testing or manual refresh)
    func clearCache() async {
        vinCache.removeAll()
        recallsCache.removeAll()
        await PersistentRecallCache.shared.clear()
    }

    // MARK: - VIN Validation

    private static let validVINCharacters = CharacterSet.alphanumerics.subtracting(
        CharacterSet(charactersIn: "IOQioq")
    )

    private func validateVIN(_ vin: String) throws {
        let trimmed = vin.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 17 else {
            throw NHTSAError.invalidVIN
        }
        guard trimmed.unicodeScalars.allSatisfy({ Self.validVINCharacters.contains($0) }) else {
            throw NHTSAError.invalidVIN
        }
    }

    // MARK: - VIN Decode

    func decodeVIN(_ vin: String) async throws -> VINDecodeResult {
        try validateVIN(vin)

        let trimmed = vin.trimmingCharacters(in: .whitespaces).uppercased()

        // Check cache first
        if let cached = vinCache[trimmed], cached.isValid(ttl: vinCacheTTL) {
            return cached.data
        }

        guard let url = URL(string: "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/\(trimmed)?format=json") else {
            throw NHTSAError.serverError
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NHTSAError.networkUnavailable
            case .timedOut:
                throw NHTSAError.timeout
            default:
                throw NHTSAError.serverError
            }
        }

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw NHTSAError.serverError
        }

        let vinResponse: VINDecodeResponse
        do {
            vinResponse = try decodeNHTSAJSON(VINDecodeResponse.self, from: data)
        } catch {
            throw NHTSAError.decodingFailed
        }

        guard let result = vinResponse.Results.first else {
            throw NHTSAError.noResultsFound
        }

        let yearInt = result.ModelYear.flatMap { Int($0) }

        // Build engine description from available fields
        var engineParts: [String] = []
        if let displacement = result.DisplacementL, !displacement.isEmpty, displacement != "0" {
            engineParts.append("\(displacement)L")
        }
        if let cylinders = result.EngineCylinders, !cylinders.isEmpty {
            engineParts.append("\(cylinders)-cyl")
        }
        if let hp = result.EngineHP, !hp.isEmpty {
            engineParts.append("\(hp) HP")
        }
        let engineDescription = engineParts.isEmpty ? (result.EngineModel ?? "") : engineParts.joined(separator: " ")

        let vinDecodeResult = VINDecodeResult(
            make: result.Make ?? "",
            model: result.Model ?? "",
            modelYear: yearInt,
            engineDescription: engineDescription,
            driveType: result.DriveType ?? "",
            bodyClass: result.BodyClass ?? "",
            fuelType: result.FuelTypePrimary ?? "",
            errorCode: result.ErrorCode ?? ""
        )

        // Cache the result
        vinCache[trimmed] = CacheEntry(data: vinDecodeResult, timestamp: Date())

        return vinDecodeResult
    }

    // MARK: - Recall Fetch

    func fetchRecalls(make: String, model: String, year: Int) async throws -> [RecallInfo] {
        let cacheKey = "\(make.lowercased())|\(model.lowercased())|\(year)"

        if let cached = recallsCache[cacheKey], cached.isValid(ttl: recallsCacheTTL) {
            return cached.data
        }

        if let persisted = await PersistentRecallCache.shared.read(key: cacheKey),
           persisted.isValid(ttl: recallsCacheTTL) {
            recallsCache[cacheKey] = persisted
            return persisted.data
        }

        do {
            let recalls = try await fetchRecallsFromNetwork(make: make, model: model, year: year)
            let entry = CacheEntry(data: recalls, timestamp: Date())
            recallsCache[cacheKey] = entry
            await PersistentRecallCache.shared.write(key: cacheKey, recalls: recalls, timestamp: entry.timestamp)
            return recalls
        } catch {
            // Fall back to any persisted data on network failure so metered-data users
            // don't lose their recall list when offline.
            if let stale = await PersistentRecallCache.shared.read(key: cacheKey) {
                recallsCache[cacheKey] = stale
                return stale.data
            }
            throw error
        }
    }

    private func fetchRecallsFromNetwork(make: String, model: String, year: Int) async throws -> [RecallInfo] {
        let encodedMake = make.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? make
        let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? model

        guard let url = URL(string: "https://api.nhtsa.gov/recalls/recallsByVehicle?make=\(encodedMake)&model=\(encodedModel)&modelYear=\(year)") else {
            throw NHTSAError.serverError
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NHTSAError.networkUnavailable
            case .timedOut:
                throw NHTSAError.timeout
            default:
                throw NHTSAError.serverError
            }
        }

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw NHTSAError.serverError
        }

        let recallsResponse: RecallsResponse
        do {
            recallsResponse = try decodeNHTSAJSON(RecallsResponse.self, from: data)
        } catch {
            throw NHTSAError.decodingFailed
        }

        return recallsResponse.results.compactMap { result in
            // Drop entries without a campaign number — id and cache key both rely on it,
            // and SwiftUI ForEach/Set would collapse multiple empty-id rows into one.
            guard let campaignNumber = result.NHTSACampaignNumber, !campaignNumber.isEmpty else {
                return nil
            }
            return RecallInfo(
                campaignNumber: campaignNumber,
                component: result.Component ?? "",
                summary: result.Summary ?? "",
                consequence: result.Consequence ?? "",
                remedy: result.Remedy ?? "",
                reportDate: result.ReportReceivedDate ?? "",
                parkIt: result.parkIt ?? false,
                parkOutside: result.parkOutSide ?? false
            )
        }
    }
}
