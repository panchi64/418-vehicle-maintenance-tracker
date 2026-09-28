import AppIntents
import Foundation
import WidgetKit

/// Which watched place a widget shows. Widget-only and snapshot-backed:
/// the places come from the App Group, never from the app's own store.
/// Keep the type's name; saved widget configurations reference it.
struct WidgetPlaceEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Lugar vigilado" }
    static var defaultQuery: WidgetPlaceQuery { WidgetPlaceQuery() }

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct WidgetPlaceQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [WidgetPlaceEntity] {
        places.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [WidgetPlaceEntity] {
        places
    }

    /// The first watched place, until the user picks one.
    func defaultResult() async -> WidgetPlaceEntity? {
        places.first
    }

    private var places: [WidgetPlaceEntity] {
        (WidgetSnapshot.load(from: SharedContainer.defaults)?.watched ?? []).map { WidgetPlaceEntity(id: $0.id, name: $0.name) }
    }
}

struct WatchedPlaceWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Lugar vigilado"
    static let description = IntentDescription("Escoge cuál de tus lugares vigilados muestra el widget.")

    @Parameter(title: "Lugar")
    var place: WidgetPlaceEntity?
}

struct WatchedPlaceProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WatchedPlaceEntry {
        WatchedPlaceEntry(glance: GlanceEntry.placeholder, placeID: nil)
    }

    func snapshot(for configuration: WatchedPlaceWidgetIntent, in context: Context) async -> WatchedPlaceEntry {
        if context.isPreview { return placeholder(in: context) }
        return WatchedPlaceEntry(glance: GlanceEntry(date: .now, snapshot: WidgetSnapshot.load(from: SharedContainer.defaults)), placeID: configuration.place?.id)
    }

    func timeline(for configuration: WatchedPlaceWidgetIntent, in context: Context) async -> Timeline<WatchedPlaceEntry> {
        let snapshot = WidgetSnapshot.load(from: SharedContainer.defaults)
        let entries = GlanceTimeline.dates(for: snapshot, from: .now).map { date in
            WatchedPlaceEntry(glance: GlanceEntry(date: date, snapshot: snapshot), placeID: configuration.place?.id)
        }
        return Timeline(entries: entries, policy: .never)
    }
}

struct WatchedPlaceEntry: TimelineEntry {
    let glance: GlanceEntry
    /// The chosen place; nil shows the first one watched.
    let placeID: UUID?

    var date: Date { glance.date }

    var place: WatchGlance? {
        let watched = glance.snapshot?.watched ?? []
        return watched.first { $0.id == placeID } ?? watched.first
    }
}
