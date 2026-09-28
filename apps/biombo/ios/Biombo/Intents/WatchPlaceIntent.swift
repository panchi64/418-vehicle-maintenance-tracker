import AppIntents
import Foundation
import UserNotifications

/// "Vigila Miradero en Biombo" (PRODUCT.md §9, §11 `WatchPlaceIntent`):
/// starts a watch with the default layers (luz, agua, carreteras cerca),
/// named as said ("Casa de Mamá") or after the place. Additive, so it
/// doesn't ask first; setup in the app changes the layers.
struct WatchPlaceIntent: AppIntent {
    static let title: LocalizedStringResource = "Vigilar un lugar"
    static let description = IntentDescription("Te avisa cuando cambien la luz, el agua o las carreteras cerca de un lugar.")

    @Parameter(title: "Lugar", requestValueDialog: "¿Qué lugar quieres vigilar?")
    var target: WatchTargetEntity

    @Parameter(title: "Nombre", description: "Cómo lo llamas, por ejemplo Casa de Mamá.")
    var name: String?

    @Dependency var context: IntentContext

    static var parameterSummary: some ParameterSummary {
        Summary("Vigilar \(\.$target)") {
            \.$name
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let outcome = Self.watch(target.draft, named: name, in: context.watches)
        let sentence = outcome.sentence(notificationsAllowed: settings.authorizationStatus == .authorized, locale: .current)
        return .result(dialog: IntentDialog(stringLiteral: sentence.string(in: .current)))
    }

    /// Saves the watch unless the place is already watched or the list is full.
    @MainActor
    static func watch(_ draft: WatchedPlace, named name: String?, in watches: WatchStore) -> WatchOutcome {
        if let existing = watches.existing(like: draft) {
            return .alreadyWatched(existing)
        }
        var watch = draft
        if let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            watch.name = name
        }
        return watches.save(watch) ? .started(watch) : .full
    }
}

/// What asking to watch a place came to.
enum WatchOutcome: Hashable {
    case started(WatchedPlace)
    case alreadyWatched(WatchedPlace)
    /// Already at `WatchedPlace.limit`.
    case full

    func sentence(notificationsAllowed: Bool, locale: Locale) -> LocalizedStringResource {
        switch self {
        case .started(let place):
            let promise = place.promise(locale: locale).string(in: locale)
            return notificationsAllowed
                ? LocalizedStringResource("Listo. Vigilamos \(place.name). \(promise)", comment: "Siri: a watch started; the place, then the watch's promise, e.g. 'Te avisamos cuando cambien la luz y el agua.'")
                : LocalizedStringResource("Listo. Vigilamos \(place.name). Para recibir avisos, abre Biombo y permite las notificaciones.", comment: "Siri: a watch started, but notifications are not allowed yet")
        case .alreadyWatched(let place):
            return LocalizedStringResource("Ya vigilas \(place.name).", comment: "Siri: the place is already watched")
        case .full:
            return LocalizedStringResource("Ya vigilas \(WatchedPlace.limit) lugares, el máximo. Quita uno en Biombo para añadir otro.", comment: "Siri: the watch list is full")
        }
    }
}
