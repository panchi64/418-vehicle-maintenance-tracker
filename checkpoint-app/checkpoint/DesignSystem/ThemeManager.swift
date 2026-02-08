//
//  ThemeManager.swift
//  checkpoint
//

import SwiftUI
import os

private let themeLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "ThemeManager")

@Observable
@MainActor
final class ThemeManager {
    static let shared = ThemeManager()

    private(set) var allThemes: [ThemeDefinition] = []
    var current: ThemeDefinition
    var ownedThemeIDs: Set<String>

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let activeThemeID = "activeThemeID"
        static let ownedThemeIDs = "ownedThemeIDs"
    }

    private init() {
        // Load themes from bundle
        let themes = Self.loadThemesFromBundle()
        self.allThemes = themes

        // Load active theme
        let activeID = UserDefaults.standard.string(forKey: Keys.activeThemeID) ?? "default"
        self.current = themes.first(where: { $0.id == activeID }) ?? themes[0]

        // Load owned theme IDs
        let ownedArray = UserDefaults.standard.stringArray(forKey: Keys.ownedThemeIDs) ?? ["default"]
        self.ownedThemeIDs = Set(ownedArray)
    }

    func activateTheme(_ id: String) {
        guard let theme = allThemes.first(where: { $0.id == id }) else { return }
        current = theme
        defaults.set(id, forKey: Keys.activeThemeID)
        themeLogger.info("Theme activated: \(id)")
    }

    func unlockTheme(_ id: String) {
        ownedThemeIDs.insert(id)
        defaults.set(Array(ownedThemeIDs), forKey: Keys.ownedThemeIDs)
        themeLogger.info("Theme unlocked: \(id)")
    }

    func unlockRandomRareTheme() -> ThemeDefinition? {
        let unownedRares = allThemes.filter { $0.tier == .rare && !ownedThemeIDs.contains($0.id) }
        guard let theme = unownedRares.randomElement() else { return nil }
        unlockTheme(theme.id)
        return theme
    }

    func isOwned(_ theme: ThemeDefinition) -> Bool {
        ownedThemeIDs.contains(theme.id)
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.activeThemeID: "default",
            Keys.ownedThemeIDs: ["default"]
        ])
    }

    private static func loadThemesFromBundle() -> [ThemeDefinition] {
        guard let url = Bundle.main.url(forResource: "Themes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            themeLogger.error("Failed to load Themes.json")
            return []
        }

        do {
            return try JSONDecoder().decode([ThemeDefinition].self, from: data)
        } catch {
            themeLogger.error("Failed to decode Themes.json: \(error.localizedDescription)")
            return []
        }
    }
}
