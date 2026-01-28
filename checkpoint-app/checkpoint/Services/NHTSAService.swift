//
//  NHTSAService.swift
//  checkpoint
//
//  NHTSA API integration for VIN decoding and recall alerts
//  Uses free, no-auth NHTSA APIs (vPIC for VIN, recalls API for safety recalls)
//

import Foundation

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

struct RecallInfo: Identifiable, Sendable {
    let id = UUID()
    let campaignNumber: String
    let component: String
    let summary: String
    let consequence: String
    let remedy: String
    let reportDate: String
    let parkIt: Bool
    let parkOutside: Bool
}

// MARK: - API Response Decodables

private struct VINDecodeResponse: Decodable, Sendable {
    let Results: [VINDecodeResultJSON]
}

private struct VINDecodeResultJSON: Decodable, Sendable {
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

private struct RecallsResponse: Decodable, Sendable {
    let Count: Int
    let results: [RecallResultJSON]
}

private struct RecallResultJSON: Decodable, Sendable {
    let NHTSACampaignNumber: String?
    let Component: String?
    let Summary: String?
    let Consequence: String?
    let Remedy: String?
    let ReportReceivedDate: String?
    let parkIt: Bool?
    let parkOutSide: Bool?
}

// MARK: - Service

actor NHTSAService {
    static let shared = NHTSAService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
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

        let decoded: VINDecodeResponse
        do {
            decoded = try JSONDecoder().decode(VINDecodeResponse.self, from: data)
        } catch {
            throw NHTSAError.decodingFailed
        }

        guard let result = decoded.Results.first else {
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

        return VINDecodeResult(
            make: result.Make ?? "",
            model: result.Model ?? "",
            modelYear: yearInt,
            engineDescription: engineDescription,
            driveType: result.DriveType ?? "",
            bodyClass: result.BodyClass ?? "",
            fuelType: result.FuelTypePrimary ?? "",
            errorCode: result.ErrorCode ?? ""
        )
    }

    // MARK: - Recall Fetch

    func fetchRecalls(make: String, model: String, year: Int) async throws -> [RecallInfo] {
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

        let decoded: RecallsResponse
        do {
            decoded = try JSONDecoder().decode(RecallsResponse.self, from: data)
        } catch {
            throw NHTSAError.decodingFailed
        }

        return decoded.results.map { result in
            RecallInfo(
                campaignNumber: result.NHTSACampaignNumber ?? "",
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
