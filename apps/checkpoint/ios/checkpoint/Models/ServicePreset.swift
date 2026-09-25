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
    var name: String = ""
    private var categoryRawValue: String = ServiceCategory.other.rawValue
    var defaultIntervalMonths: Int?
    var defaultIntervalMiles: Int?
    var isCustom: Bool = false

    var category: ServiceCategory {
        get { ServiceCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

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
}
