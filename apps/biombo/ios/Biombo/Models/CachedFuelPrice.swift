import Foundation
import SwiftData

@Model
final class CachedFuelPrice {
    @Attribute(.unique) var recordID: String
    var stationName: String
    var brand: String?
    var municipality: String?
    var latitude: Double
    var longitude: Double
    var regularPrice: Double?
    var premiumPrice: Double?
    var dieselPrice: Double?
    var source: String
    var reportedAt: Date
    var expiresAt: Date
    var confirmationCount: Int
    var flagCount: Int
    var dacoDeltaRegular: Double?
    var dacoDeltaPremium: Double?
    var dacoDeltaDiesel: Double?
    var thumbnailData: Data?

    init(
        recordID: String,
        stationName: String,
        brand: String? = nil,
        municipality: String? = nil,
        latitude: Double,
        longitude: Double,
        regularPrice: Double? = nil,
        premiumPrice: Double? = nil,
        dieselPrice: Double? = nil,
        source: String,
        reportedAt: Date,
        expiresAt: Date,
        confirmationCount: Int = 0,
        flagCount: Int = 0,
        dacoDeltaRegular: Double? = nil,
        dacoDeltaPremium: Double? = nil,
        dacoDeltaDiesel: Double? = nil,
        thumbnailData: Data? = nil
    ) {
        self.recordID = recordID
        self.stationName = stationName
        self.brand = brand
        self.municipality = municipality
        self.latitude = latitude
        self.longitude = longitude
        self.regularPrice = regularPrice
        self.premiumPrice = premiumPrice
        self.dieselPrice = dieselPrice
        self.source = source
        self.reportedAt = reportedAt
        self.expiresAt = expiresAt
        self.confirmationCount = confirmationCount
        self.flagCount = flagCount
        self.dacoDeltaRegular = dacoDeltaRegular
        self.dacoDeltaPremium = dacoDeltaPremium
        self.dacoDeltaDiesel = dacoDeltaDiesel
        self.thumbnailData = thumbnailData
    }

    var isExpired: Bool { expiresAt < Date() }

    var freshness: Freshness {
        let age = Date().timeIntervalSince(reportedAt)
        switch age {
        case ..<(6 * 3600): return .fresh
        case (6 * 3600)..<(24 * 3600): return .aging
        default: return .stale
        }
    }

    enum Freshness {
        case fresh, aging, stale
    }
}

extension CachedFuelPrice: Identifiable {
    var id: String { recordID }

    struct GradeEntry: Identifiable {
        enum Grade: String { case regular, premium, diesel }
        let id: Grade
        let price: Double
        let delta: Double?
    }

    var gradeEntries: [GradeEntry] {
        [
            (.regular, regularPrice, dacoDeltaRegular),
            (.premium, premiumPrice, dacoDeltaPremium),
            (.diesel, dieselPrice, dacoDeltaDiesel)
        ].compactMap { grade, price, delta in
            price.map { GradeEntry(id: grade, price: $0, delta: delta) }
        }
    }

    var hasDacoDelta: Bool {
        dacoDeltaRegular != nil || dacoDeltaPremium != nil || dacoDeltaDiesel != nil
    }
}
