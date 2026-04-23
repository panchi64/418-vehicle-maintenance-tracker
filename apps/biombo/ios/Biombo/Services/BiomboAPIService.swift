import Foundation

struct DACOStationDTO: Decodable {
    let id: String
    let brand: String
    let stationName: String?
    let municipality: String?
    let latitude: Double?
    let longitude: Double?
    let regular: Double?
    let premium: Double?
    let diesel: Double?
}

struct CommunitySubmissionDTO: Decodable {
    let id: String
    let detectedBrand: String?
    let stationName: String?
    let latitude: Double
    let longitude: Double
    let parsedRegular: Double?
    let parsedPremium: Double?
    let parsedDiesel: Double?
    let dacoDeltaRegular: Double?
    let dacoDeltaPremium: Double?
    let dacoDeltaDiesel: Double?
    let createdAt: Date
    let expiresAt: Date
    let confirmationCount: Int
    let flagCount: Int
}

struct PricesResponse: Decodable {
    let snapshotId: String?
    let scrapedAt: Date?
    let daco: [DACOStationDTO]
    let community: [CommunitySubmissionDTO]
}

struct PriceHistoryResponse: Decodable {
    struct Point: Decodable {
        let date: Date
        let regular: Double?
        let premium: Double?
        let diesel: Double?
    }
    let stationId: String?
    let points: [Point]
}

struct BrandsResponse: Decodable {
    let brands: [String]
}

struct SubmissionRequest: Encodable {
    let deviceToken: String
    let detectedBrand: String?
    let stationName: String?
    let latitude: Double
    let longitude: Double
    let parsedRegular: Double?
    let parsedPremium: Double?
    let parsedDiesel: Double?
    let ocrText: String?
}

struct SubmissionResponse: Decodable {
    let submission: CommunitySubmissionDTO
}

enum BiomboAPIError: Error, LocalizedError {
    case badResponse(status: Int)
    case decoding(Error)
    case transport(Error)
    case encoding(Error)

    var errorDescription: String? {
        switch self {
        case .badResponse(let status): return "Server returned HTTP \(status)"
        case .decoding(let err): return "Couldn't decode response: \(err.localizedDescription)"
        case .transport(let err): return err.localizedDescription
        case .encoding(let err): return "Couldn't encode request: \(err.localizedDescription)"
        }
    }
}

actor BiomboAPIService {
    static let shared = BiomboAPIService()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL ?? Self.resolvedBaseURL
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
        self.encoder = JSONEncoder()
    }

    func fetchCurrentPrices() async throws -> PricesResponse {
        try await get("/prices/current")
    }

    func fetchHistory(stationId: String, days: Int = 30) async throws -> PriceHistoryResponse {
        try await get("/prices/history?stationId=\(stationId)&days=\(days)")
    }

    func fetchBrands() async throws -> BrandsResponse {
        try await get("/brands")
    }

    func submitPrice(_ request: SubmissionRequest, imageData: Data) async throws -> SubmissionResponse {
        let url = baseURL.appending(path: "/submissions")
        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let metadata: Data
        do {
            metadata = try encoder.encode(request)
        } catch {
            throw BiomboAPIError.encoding(error)
        }

        urlRequest.httpBody = Self.multipartBody(boundary: boundary, metadata: metadata, imageData: imageData)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            try Self.validate(response)
            return try decoder.decode(SubmissionResponse.self, from: data)
        } catch let error as BiomboAPIError {
            throw error
        } catch let error as DecodingError {
            throw BiomboAPIError.decoding(error)
        } catch {
            throw BiomboAPIError.transport(error)
        }
    }

    enum Interaction: String {
        case confirm, flag
    }

    func postInteraction(_ kind: Interaction, submissionId: String, deviceToken: String) async throws {
        try await postJSON("/submissions/\(submissionId)/\(kind.rawValue)", body: ["deviceToken": deviceToken])
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appending(path: path)
        do {
            let (data, response) = try await session.data(from: url)
            try Self.validate(response)
            return try decoder.decode(T.self, from: data)
        } catch let error as BiomboAPIError {
            throw error
        } catch let error as DecodingError {
            throw BiomboAPIError.decoding(error)
        } catch {
            throw BiomboAPIError.transport(error)
        }
    }

    private func postJSON(_ path: String, body: [String: String]) async throws {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        do {
            let (_, response) = try await session.data(for: request)
            try Self.validate(response)
        } catch let error as BiomboAPIError {
            throw error
        } catch {
            throw BiomboAPIError.transport(error)
        }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw BiomboAPIError.badResponse(status: 0)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw BiomboAPIError.badResponse(status: http.statusCode)
        }
    }

    static func multipartBody(boundary: String, metadata: Data, imageData: Data) -> Data {
        var body = Data()
        let newline = "\r\n"

        body.append("--\(boundary)\(newline)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"metadata\"\(newline)\(newline)".data(using: .utf8)!)
        body.append(metadata)
        body.append(newline.data(using: .utf8)!)

        body.append("--\(boundary)\(newline)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"price.jpg\"\(newline)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(newline)\(newline)".data(using: .utf8)!)
        body.append(imageData)
        body.append(newline.data(using: .utf8)!)

        body.append("--\(boundary)--\(newline)".data(using: .utf8)!)
        return body
    }

    private static var resolvedBaseURL: URL {
        if let override = ProcessInfo.processInfo.environment["BIOMBO_API_URL"],
           let url = URL(string: override) {
            return url
        }
        if let configured = Bundle.main.object(forInfoDictionaryKey: "BiomboAPIURL") as? String,
           let url = URL(string: configured) {
            return url
        }
        return URL(string: "http://localhost:8787")!
    }
}
