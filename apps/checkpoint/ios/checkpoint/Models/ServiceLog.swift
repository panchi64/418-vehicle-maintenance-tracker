//
//  ServiceLog.swift
//  checkpoint
//
//  SwiftData model for completed service records
//

import Foundation
import SwiftData

@Model
final class ServiceLog: Identifiable {
    var id: UUID = UUID()
    var service: Service?
    var vehicle: Vehicle?
    var performedDate: Date = Date.now
    var mileageAtService: Int = 0
    var cost: Decimal?
    var costCategory: CostCategory?
    var notes: String?
    var createdAt: Date = Date.now

    /// Parent Service Visit when this log was completed as part of a multi-service
    /// shop visit. nil for standalone single-service logs created before the
    /// Service Visit feature, and for any imported standalone log.
    var visit: ServiceVisit?

    /// `.nullify`, not `.cascade`: attachments are Documents in their own
    /// library, linked to vehicles independently of any log. Deleting a log
    /// (or a Service, which cascades to its logs) must not hard-delete the
    /// user's receipts — it only detaches them from the log. A document that
    /// ends up with neither a log nor a vehicle is swept by
    /// `Document.purgeOrphans`; documents are ultimately deleted with their
    /// vehicle (via `Vehicle.documents` .nullify + the orphan sweep).
    @Relationship(deleteRule: .nullify, inverse: \ServiceAttachment.serviceLog)
    var attachments: [ServiceAttachment]? = []

    var formattedCost: String? {
        guard let cost = cost else { return nil }
        return Formatters.currency.string(from: cost as NSDecimalNumber)
    }

    var daysSincePerformed: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: performedDate, to: Date.now).day ?? 0
        return days
    }

    init(
        service: Service? = nil,
        vehicle: Vehicle? = nil,
        performedDate: Date,
        mileageAtService: Int,
        cost: Decimal? = nil,
        costCategory: CostCategory? = nil,
        notes: String? = nil,
        createdAt: Date = Date.now
    ) {
        self.service = service
        self.vehicle = vehicle
        self.performedDate = performedDate
        self.mileageAtService = mileageAtService
        self.cost = cost
        self.costCategory = costCategory
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Sample Data

extension ServiceLog {
    /// Helper to create a Date from year/month/day components
    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? .now
    }

    /// 21 service logs spanning Jun 2024 → Feb 2026 for a daily driver (Camry)
    static func sampleLogs(for vehicle: Vehicle, service: Service? = nil) -> [ServiceLog] {
        // 2024 (7 entries)
        let logs2024: [(String, Date, Int, Decimal, CostCategory, String?)] = [
            ("Coolant flush", date(2024, 6, 12), 20500, 95, .maintenance, nil),
            ("Cabin air filter", date(2024, 7, 20), 21200, 22, .maintenance, "Replaced cabin filter"),
            ("Battery replacement", date(2024, 8, 5), 22000, 175, .repair, "Battery died unexpectedly. Replaced with Interstate."),
            ("Floor mats (WeatherTech)", date(2024, 9, 14), 22800, 150, .upgrade, "WeatherTech all-weather floor mats"),
            ("Oil change", date(2024, 10, 3), 23500, 46, .maintenance, "Synthetic 0W-20"),
            ("Front brake pads", date(2024, 11, 18), 24500, 285, .repair, "Front brake pads worn. Replaced with ceramic pads."),
            ("Wiper blades", date(2024, 12, 7), 25200, 28, .maintenance, nil),
        ]

        // 2025 (12 entries)
        let logs2025: [(String, Date, Int, Decimal, CostCategory, String?)] = [
            ("Tire rotation", date(2025, 1, 11), 25800, 35, .maintenance, "Rotated and balanced all four tires"),
            ("Oil change", date(2025, 2, 15), 26500, 48, .maintenance, "Synthetic 0W-20"),
            ("Wheel alignment", date(2025, 3, 22), 27000, 110, .repair, "Slight pull to the right corrected"),
            ("Cabin air filter", date(2025, 4, 8), 27500, 25, .maintenance, "Replaced cabin filter"),
            ("Dash cam install", date(2025, 5, 17), 28200, 180, .upgrade, "Viofo A129 Pro Duo front + rear"),
            ("Oil change", date(2025, 6, 21), 28800, 46, .maintenance, "Synthetic 0W-20"),
            ("Tire rotation", date(2025, 7, 5), 29300, 35, .maintenance, "Rotated and balanced"),
            ("Rear brake pads", date(2025, 8, 14), 30000, 320, .repair, "Rear pads worn. Replaced with ceramic."),
            ("LED headlights", date(2025, 9, 2), 30500, 95, .upgrade, "Upgraded to LED bulbs"),
            ("Oil change", date(2025, 10, 18), 31000, 48, .maintenance, "Synthetic 0W-20"),
            ("Transmission fluid", date(2025, 11, 9), 31500, 165, .maintenance, "Full transmission fluid exchange"),
            ("Air filter", date(2025, 12, 20), 31800, 28, .maintenance, "Replaced engine air filter"),
        ]

        // 2026 (2 entries)
        let logs2026: [(String, Date, Int, Decimal, CostCategory, String?)] = [
            ("Tire rotation", date(2026, 1, 10), 32000, 35, .maintenance, "Rotated and balanced"),
            ("Oil change", date(2026, 2, 1), 32200, 46, .maintenance, "Synthetic 0W-20"),
        ]

        let allEntries = logs2024 + logs2025 + logs2026

        return allEntries.map { name, performedDate, mileage, cost, category, notes in
            ServiceLog(
                service: service,
                vehicle: vehicle,
                performedDate: performedDate,
                mileageAtService: mileage,
                cost: cost,
                costCategory: category,
                notes: notes
            )
        }
    }

    /// 6 service logs for a secondary vehicle (NSX Type R), Mar 2025 → Jan 2026
    static func sampleLogsCompact(for vehicle: Vehicle, service: Service? = nil) -> [ServiceLog] {
        let entries: [(String, Date, Int, Decimal, CostCategory, String?)] = [
            ("Oil change", date(2025, 3, 8), 16800, 68, .maintenance, "10W-30 full synthetic"),
            ("Summer tires", date(2025, 5, 20), 17200, 920, .upgrade, "Michelin Pilot Sport 4S, staggered 15/16"),
            ("Oil change", date(2025, 7, 12), 17500, 68, .maintenance, "10W-30 full synthetic"),
            ("Brake fluid flush", date(2025, 9, 6), 17800, 95, .maintenance, "DOT 4 full flush"),
            ("Oil change", date(2025, 11, 15), 18000, 68, .maintenance, "10W-30 full synthetic"),
            ("Professional detailing", date(2026, 1, 18), 18100, 240, .upgrade, "Full interior + exterior detail"),
        ]

        return entries.map { name, performedDate, mileage, cost, category, notes in
            ServiceLog(
                service: service,
                vehicle: vehicle,
                performedDate: performedDate,
                mileageAtService: mileage,
                cost: cost,
                costCategory: category,
                notes: notes
            )
        }
    }
}
