//
//  PresetDataService.swift
//  checkpoint
//
//  Service for loading bundled service preset data from JSON
//

import Foundation

struct PresetData: Codable, Equatable {
    let name: String
    let category: String
    let defaultIntervalMonths: Int?
    let defaultIntervalMiles: Int?
}

class PresetDataService {
    static let shared = PresetDataService()

    private var cachedPresets: [PresetData]?

    private init() {}

    /// Load presets from bundled JSON file
    /// Returns empty array if file not found or parsing fails
    func loadPresets() -> [PresetData] {
        // Return cached data if available
        if let cached = cachedPresets {
            return cached
        }

        // Locate the JSON file in the bundle
        guard let url = Bundle.main.url(forResource: "ServicePresets", withExtension: "json") else {
            print("Error: ServicePresets.json not found in bundle")
            return []
        }

        do {
            // Load and decode the JSON data
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let presets = try decoder.decode([PresetData].self, from: data)

            // Cache the results
            cachedPresets = presets
            return presets
        } catch {
            print("Error loading presets: \(error)")
            return []
        }
    }

    /// Get presets filtered by category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of presets matching the category
    func presets(for category: ServiceCategory) -> [PresetData] {
        let allPresets = loadPresets()
        return allPresets.filter { $0.category.lowercased() == category.rawValue.lowercased() }
    }

    /// Get all category names that have presets
    /// - Returns: Array of unique categories that have at least one preset
    func availableCategories() -> [ServiceCategory] {
        let allPresets = loadPresets()
        let categoryStrings = Set(allPresets.map { $0.category.lowercased() })

        // Map category strings to ServiceCategory enum values
        let categories = ServiceCategory.allCases.filter { category in
            categoryStrings.contains(category.rawValue.lowercased())
        }

        return categories
    }
}
