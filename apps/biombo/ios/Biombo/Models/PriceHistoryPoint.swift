import Foundation
import SwiftData

@Model
final class PriceHistoryPoint {
    var stationId: String
    var date: Date
    var regular: Double?
    var premium: Double?
    var diesel: Double?

    init(
        stationId: String,
        date: Date,
        regular: Double? = nil,
        premium: Double? = nil,
        diesel: Double? = nil
    ) {
        self.stationId = stationId
        self.date = date
        self.regular = regular
        self.premium = premium
        self.diesel = diesel
    }
}

extension PriceHistoryPoint: Identifiable {
    var id: String { "\(stationId)-\(date.timeIntervalSince1970)" }
}
