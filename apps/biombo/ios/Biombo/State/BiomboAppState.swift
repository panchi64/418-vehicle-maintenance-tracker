import Foundation
import SwiftUI
import Observation

enum BiomboViewMode: String, CaseIterable, Identifiable {
    case map, list
    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .map: return "view.map"
        case .list: return "view.list"
        }
    }
}

enum VolumeUnit: String, CaseIterable, Identifiable {
    case liters, gallons
    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .liters: return "shared.units.liters"
        case .gallons: return "shared.units.gallons"
        }
    }
}

@Observable
final class BiomboAppState {
    var viewMode: BiomboViewMode = .map
    var volumeUnit: VolumeUnit = .liters
    var selectedStationId: String?
    var showingSubmitSheet: Bool = false
    var showingSettings: Bool = false
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: Keys.completedOnboarding)

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Keys.completedOnboarding)
    }

    private enum Keys {
        static let completedOnboarding = "biombo.completedOnboarding"
    }
}
