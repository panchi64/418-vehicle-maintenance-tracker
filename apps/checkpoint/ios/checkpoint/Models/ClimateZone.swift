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
        case .coldWinter: return L10n.climateColdWinterName
        case .mildFourSeason: return L10n.climateMildFourSeasonName
        case .hotDry: return L10n.climateHotDryName
        case .hotHumid: return L10n.climateHotHumidName
        case .tropical: return L10n.climateTropicalName
        }
    }

    var description: String {
        switch self {
        case .coldWinter: return L10n.climateColdWinterDetail
        case .mildFourSeason: return L10n.climateMildFourSeasonDetail
        case .hotDry: return L10n.climateHotDryDetail
        case .hotHumid: return L10n.climateHotHumidDetail
        case .tropical: return L10n.climateTropicalDetail
        }
    }
}
