import Foundation

/// Search in the sheet: places and municipios, ignoring case and accents so
/// "rio piedras" finds "Río Piedras".
nonisolated struct PlaceSearch: Sendable {
    nonisolated enum Result: Identifiable, Hashable, Sendable {
        case municipio(name: String, anchor: GeoPoint)
        case place(Place)

        var id: String {
            switch self {
            case .municipio(let name, _): "municipio#\(name)"
            case .place(let place): place.id
            }
        }

        var anchor: GeoPoint {
            switch self {
            case .municipio(_, let anchor): anchor
            case .place(let place): place.anchor
            }
        }
    }

    /// Results shown at once (*proposed*).
    var limit = 12

    /// Word-start matches before matches inside a word; within each, municipios
    /// before places, then nearest ("rio" lists Río Piedras before Comerío).
    func results(for query: String, in places: [Place], near vantage: GeoPoint) -> [Result] {
        let needle = Self.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }

        let municipios = Dictionary(grouping: places, by: \.municipio)
            .compactMap { name, group -> Ranked? in
                let match = rank(needle, in: name)
                guard match != .max, let anchor = GeoPoint.centroid(of: group.map(\.anchor)) else { return nil }
                return Ranked(result: .municipio(name: name, anchor: anchor), match: match, kind: 0, distance: vantage.distance(to: anchor))
            }

        let matches = places.compactMap { place -> Ranked? in
            let fields = [place.name, place.barrio ?? "", place.brand ?? ""]
            let match = fields.map { rank(needle, in: $0) }.min() ?? .max
            guard match != .max else { return nil }
            return Ranked(result: .place(place), match: match, kind: 1, distance: vantage.distance(to: place.anchor))
        }

        return (municipios + matches)
            .sorted { ($0.match, $0.kind, $0.distance, $0.result.id) < ($1.match, $1.kind, $1.distance, $1.result.id) }
            .prefix(limit)
            .map(\.result)
    }

    private struct Ranked {
        let result: Result
        /// 0 at a word start, 1 inside a word.
        let match: Int
        /// 0 for a municipio, 1 for a place.
        let kind: Int
        let distance: Double
    }

    /// 0 for a prefix of the field or of one of its words, 1 inside a word, `Int.max` for no match.
    private func rank(_ needle: String, in field: String) -> Int {
        let folded = Self.fold(field)
        guard folded.contains(needle) else { return .max }
        let words = folded.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        return folded.hasPrefix(needle) || words.contains { $0.hasPrefix(needle) } ? 0 : 1
    }

    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
    }
}
