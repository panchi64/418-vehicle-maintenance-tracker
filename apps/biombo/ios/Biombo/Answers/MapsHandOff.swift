import Foundation

/// "Abrir en…" (PRODUCT.md §6.7, open decision 13): directions in another
/// app. No public deep link adds a stop to an active route, so every app
/// opens directions to the place, and Biombo plans no routes itself.
nonisolated enum MapsApp: String, CaseIterable, Hashable, Sendable {
    case appleMaps
    case googleMaps
    case waze

    /// The scheme probed to learn whether the app is installed; Apple Maps always is.
    /// Each probed scheme is listed under `LSApplicationQueriesSchemes`.
    var probeURL: URL? {
        switch self {
        case .appleMaps: nil
        case .googleMaps: URL(string: "comgooglemaps://")
        case .waze: URL(string: "waze://")
        }
    }

    /// Driving directions to `point`.
    func directionsURL(to point: GeoPoint) -> URL {
        let coordinate = "\(point.latitude),\(point.longitude)"
        var components: URLComponents
        switch self {
        case .appleMaps:
            components = URLComponents(string: "https://maps.apple.com/")!
            components.queryItems = [URLQueryItem(name: "daddr", value: coordinate), URLQueryItem(name: "dirflg", value: "d")]
        case .googleMaps:
            components = URLComponents(string: "comgooglemaps://")!
            components.queryItems = [URLQueryItem(name: "daddr", value: coordinate), URLQueryItem(name: "directionsmode", value: "driving")]
        case .waze:
            components = URLComponents(string: "waze://")!
            components.queryItems = [URLQueryItem(name: "ll", value: coordinate), URLQueryItem(name: "navigate", value: "yes")]
        }
        return components.url!
    }
}

/// What "Abrir en…" does: open the only app there is, or ask among the installed ones.
nonisolated enum MapsHandOff: Hashable, Sendable {
    case open(MapsApp)
    case choose([MapsApp])

    /// Only installed apps are offered, in a fixed order; Apple Maps is always there.
    init(installed: Set<MapsApp>) {
        let apps = MapsApp.allCases.filter { $0 == .appleMaps || installed.contains($0) }
        self = apps.count == 1 ? .open(apps[0]) : .choose(apps)
    }
}
