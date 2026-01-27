//
//  ServicePreset.swift
//  checkpoint
//
//  SwiftData model for service type presets
//

import Foundation
import SwiftData

enum ServiceCategory: String, Codable, CaseIterable {
    case engine = "Engine"
    case tires = "Tires"
    case brakes = "Brakes"
    case transmission = "Transmission"
    case fluids = "Fluids"
    case electrical = "Electrical"
    case body = "Body"
    case other = "Other"

    var icon: String {
        switch self {
        case .engine: return "engine.combustion"
        case .tires: return "tire"
        case .brakes: return "brake.signal"
        case .transmission: return "gear"
        case .fluids: return "drop.fill"
        case .electrical: return "bolt.car"
        case .body: return "car.side"
        case .other: return "wrench.and.screwdriver"
        }
    }
}

@Model
final class ServicePreset {
    var name: String
    var category: ServiceCategory
    var defaultIntervalMonths: Int?
    var defaultIntervalMiles: Int?
    var isCustom: Bool

    init(
        name: String,
        category: ServiceCategory,
        defaultIntervalMonths: Int? = nil,
        defaultIntervalMiles: Int? = nil,
        isCustom: Bool = false
    ) {
        self.name = name
        self.category = category
        self.defaultIntervalMonths = defaultIntervalMonths
        self.defaultIntervalMiles = defaultIntervalMiles
        self.isCustom = isCustom
    }

    @MainActor
    var intervalDescription: String? {
        let hasMonths = defaultIntervalMonths != nil
        let hasMiles = defaultIntervalMiles != nil

        guard hasMonths || hasMiles else { return nil }

        var components: [String] = []

        if let months = defaultIntervalMonths {
            let monthText = months == 1 ? "month" : "months"
            components.append("\(months) \(monthText)")
        }

        if let miles = defaultIntervalMiles {
            let unit = DistanceSettings.shared.unit
            let displayValue = unit.fromMiles(miles)
            let formattedDistance = NumberFormatter.localizedString(from: NSNumber(value: displayValue), number: .decimal)
            components.append("\(formattedDistance) \(unit.fullName)")
        }

        if components.count == 2 {
            return "Every \(components[0]) or \(components[1])"
        } else {
            return "Every \(components[0])"
        }
    }
}
