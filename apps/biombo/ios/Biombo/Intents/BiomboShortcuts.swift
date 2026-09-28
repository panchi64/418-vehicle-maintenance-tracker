import AppIntents

/// The App Shortcuts: voice that works the moment Biombo is installed
/// (PRODUCT.md §11). Every phrase names the app, as App Shortcuts require,
/// so "Oye Siri, reporta que no hay luz" is said "Reporta en Biombo que no
/// hay luz" (open decision 14). Spanish is the source; the English phrases
/// are in `AppShortcuts.xcstrings`. A Siri tip shows its shortcut's first
/// phrase as written, so each first phrase carries no parameter. Up to 10;
/// five are used. The app calls `updateAppShortcutParameters()` when the
/// watch list changes, so "Cómo está Casa de Mamá" knows the names.
struct BiomboShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReportConditionIntent(),
            phrases: [
                "Reporta en \(.applicationName)",
                "Reporta en \(.applicationName) que \(\.$condition)",
                "Avisa en \(.applicationName) que \(\.$condition)",
                "Dile a \(.applicationName) que \(\.$condition)"
            ],
            shortTitle: "Reportar",
            systemImageName: "plus.bubble"
        )

        AppShortcut(
            intent: CheckConditionIntent(),
            phrases: [
                "Pregúntale a \(.applicationName) si hay luz",
                "Pregúntale a \(.applicationName) si hay \(\.$service)",
                "¿Hay \(\.$service) según \(.applicationName)?"
            ],
            shortTitle: "¿Hay luz?",
            systemImageName: "bolt"
        )

        AppShortcut(
            intent: CheckWatchedPlaceIntent(),
            phrases: [
                "Cómo están mis lugares en \(.applicationName)",
                "Cómo está \(\.$place) en \(.applicationName)"
            ],
            shortTitle: "Lugar vigilado",
            systemImageName: "eye"
        )

        AppShortcut(
            intent: CheckFuelIntent(),
            phrases: [
                "Dónde hay gasolina barata en \(.applicationName)",
                "Busca gasolina en \(.applicationName)"
            ],
            shortTitle: "Gasolina cerca",
            systemImageName: "fuelpump"
        )

        AppShortcut(
            intent: WatchPlaceIntent(),
            // No phrase with the place: it is found by search, so Siri asks for it.
            phrases: [
                "Vigila un lugar en \(.applicationName)",
                "Empieza a vigilar un lugar en \(.applicationName)"
            ],
            shortTitle: "Vigilar un lugar",
            systemImageName: "eye.circle"
        )
    }
}
