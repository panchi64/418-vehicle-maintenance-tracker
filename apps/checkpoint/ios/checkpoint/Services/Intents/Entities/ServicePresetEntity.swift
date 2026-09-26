//
//  ServicePresetEntity.swift
//  checkpoint
//
//  A bundled service type ("Oil Change", every 6 months / 5,000 miles), for
//  intents that add a service by name. Read from `PresetDataService`, not
//  SwiftData, and not indexed in Spotlight: presets are the app's catalog,
//  not the user's data, so searching them from the home screen would surface
//  noise. The name is the ID — the catalog has no other stable key.
//

import AppIntents

struct ServicePresetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Service Type", numericFormat: "\(placeholder: .int) service types")
    }

    static var defaultQuery: ServicePresetEntityQuery { ServicePresetEntityQuery() }

    let id: String

    @Property(title: "Category")
    var category: String

    @Property(title: "Interval (Months)")
    var defaultIntervalMonths: Int?

    /// In miles.
    @Property(title: "Interval (Miles)")
    var defaultIntervalMiles: Int?

    var name: String { id }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(category)")
    }

    @MainActor
    init(preset: PresetData) {
        id = preset.name
        category = preset.category
        defaultIntervalMonths = preset.defaultIntervalMonths
        defaultIntervalMiles = preset.defaultIntervalMiles
    }

    /// Every preset, catalog order.
    @MainActor
    static func all() -> [ServicePresetEntity] {
        PresetDataService.shared.loadPresets().map(ServicePresetEntity.init(preset:))
    }

    @MainActor
    static func entities(matching text: String) -> [ServicePresetEntity] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return all() }
        return all().filter { $0.name.localizedStandardContains(needle) }
    }
}

struct ServicePresetEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ServicePresetEntity] {
        let wanted = Set(identifiers)
        return await ServicePresetEntity.all().filter { wanted.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [ServicePresetEntity] {
        await ServicePresetEntity.entities(matching: string)
    }

    func suggestedEntities() async throws -> [ServicePresetEntity] {
        await ServicePresetEntity.all()
    }
}
