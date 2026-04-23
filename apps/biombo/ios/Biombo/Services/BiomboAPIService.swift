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

enum BiomboAPIError: Error, LocalizedError {
    case badResponse(status: Int)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .badResponse(let status): return "Server returned HTTP \(status)"
        case .decoding(let err): return "Couldn't decode response: \(err.localizedDescription)"
        case .transport(let err): return err.localizedDescription
        }
    }
}

actor BiomboAPIService {
    static let shared = BiomboAPIService()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL = URL(string: "http://localhost:8787")!,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
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

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appending(path: path)
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw BiomboAPIError.badResponse(status: status)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw BiomboAPIError.decoding(error)
            }
        } catch let error as BiomboAPIError {
            throw error
        } catch {
            throw BiomboAPIError.transport(error)
        }
    }
}
