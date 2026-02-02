//
//  MileageEstimateSettings.swift
//  checkpoint
//
//  Simple settings for mileage estimate display
//

import Foundation

/// Settings for mileage estimation feature
@Observable
@MainActor
final class MileageEstimateSettings {
    static let shared = MileageEstimateSettings()

    private static let showEstimatesKey = "showMileageEstimates"

    /// Whether to show estimated mileage (default: true)
    var showEstimates: Bool {
        didSet {
            guard showEstimates != oldValue else { return }
            UserDefaults.standard.set(showEstimates, forKey: Self.showEstimatesKey)
        }
    }

    private init() {
        // Default to true - estimates shown by default
        UserDefaults.standard.register(defaults: [Self.showEstimatesKey: true])
        self.showEstimates = UserDefaults.standard.bool(forKey: Self.showEstimatesKey)
    }
}
