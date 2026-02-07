//
//  ClimateZone.swift
//  checkpoint
//
//  Climate zone enum for seasonal maintenance reminders
//

import Foundation

enum ClimateZone: String, CaseIterable, Codable {
    case coldWinter = "coldWinter"
    case mildFourSeason = "mildFourSeason"
    case hotDry = "hotDry"
    case hotHumid = "hotHumid"
    case tropical = "tropical"

    var displayName: String {
        switch self {
        case .coldWinter: return "Cold Winters"
        case .mildFourSeason: return "Mild Four-Season"
        case .hotDry: return "Hot & Dry"
        case .hotHumid: return "Hot & Humid"
        case .tropical: return "Tropical"
        }
    }

    var description: String {
        switch self {
        case .coldWinter: return "Northeast, Midwest, Mountain — harsh winters, road salt"
        case .mildFourSeason: return "Mid-Atlantic, Pacific NW — moderate winters"
        case .hotDry: return "Southwest, desert — extreme heat, minimal rain"
        case .hotHumid: return "Southeast, Gulf Coast — heat, humidity, heavy rain"
        case .tropical: return "Hawaii, PR, USVI — year-round warm"
        }
    }
}
