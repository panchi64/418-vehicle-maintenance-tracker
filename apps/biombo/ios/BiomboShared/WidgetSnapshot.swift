import Foundation

/// What the widgets show, written by the app into the App Group whenever
/// its answers change (PRODUCT.md §11 "Other system surfaces"). Words come
/// already in the app's language; the extension adds only its own chrome.
///
/// Every glance carries `freshUntil` on the device's clock. Past it, a
/// widget says "Sin reportes recientes" instead of keeping an old value
/// (§3 "Truth before completeness").
nonisolated struct WidgetSnapshot: Codable, Hashable, Sendable {
    /// When the app wrote it, on the device's clock.
    var writtenAt: Date
    var isCrisis: Bool
    /// The cheapest current price near you, or in crisis the nearest
    /// station with gas; nil when nothing current is in reach.
    var gas: GasGlance?
    /// The watched places, in the watch list's order.
    var watched: [WatchGlance]

    static let storageKey = "widgetSnapshot"

    static func load(from defaults: UserDefaults?) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(to defaults: UserDefaults?) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults?.set(data, forKey: Self.storageKey)
    }

    static func erase(from defaults: UserDefaults?) {
        defaults?.removeObject(forKey: storageKey)
    }

    /// The moments after `date` when something shown goes stale, soonest
    /// first, so a timeline can turn to "Sin reportes recientes" on time.
    func expiries(after date: Date) -> [Date] {
        let all = [gas?.freshUntil].compactMap(\.self) + watched.map(\.freshUntil)
        return Array(Set(all.filter { $0 > date })).sorted()
    }
}

/// "Gasolina cerca": one station and its answer.
nonisolated struct GasGlance: Codable, Hashable, Sendable {
    /// "$0.99", or "Hay gasolina" in crisis.
    var value: String
    /// "/L" or "/gal" beside a price; nil beside a status.
    var unit: String?
    /// "$0.99/L" in one line (the rectangular and inline widgets), or
    /// "Hay gasolina" beside a status.
    var compact: String
    /// "Puma", the station as people say it.
    var station: String
    /// "Bo. Pueblo · 0.8 km".
    var whereLine: String
    /// "4:10 p. m.", when the answer was last said.
    var asOfClock: String
    /// The whole glance as one VoiceOver sentence.
    var spoken: String
    var freshUntil: Date

    func isFresh(at date: Date) -> Bool { date < freshUntil }
}

/// One watched place ("Casa de Mamá") and what changed there.
nonisolated struct WatchGlance: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var name: String
    /// "Miradero, Mayagüez".
    var whereLine: String
    /// Confirmed changes, most urgent first. Empty reads `normalLine`.
    var lines: [GlanceLine]
    /// "Todo normal".
    var normalLine: String
    var freshUntil: Date

    func isFresh(at date: Date) -> Bool { date < freshUntil }
}

/// One change: its symbol, sentence and who says so.
nonisolated struct GlanceLine: Codable, Hashable, Sendable {
    var symbol: String
    /// "Sin luz desde las 3:10 p. m."
    var text: String
    /// "Oficial · LUMA", "Confirmado hace 12 min".
    var source: String
}
