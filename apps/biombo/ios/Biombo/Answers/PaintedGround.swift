import CoreGraphics
import Foundation

/// The painted island's zoom contract (direction: "painted-to-plain is a
/// zoom contract"): the whole painting at island zoom, fading through
/// municipio zoom, gone at street zoom. Pins, labels and areas never change;
/// only the ground does. Pure geometry and opacity, so it can be tested.
nonisolated enum PaintedGround {
    /// The raster's geographic bounds, printed by `scripts/render_art.py`.
    nonisolated static let north = 18.6545
    nonisolated static let south = 17.7938
    nonisolated static let west = -67.3493
    nonisolated static let east = -65.1409

    /// Opacity stops by visible span (degrees, narrower side), smooth in
    /// log-span: full at island zoom, 60%→20% across municipio zoom, none at street zoom.
    nonisolated static let stops: [(span: Double, opacity: Double)] = [
        (0.12, 0), (0.15, 0.2), (ZoomTier.islandSpan, 0.6), (0.9, 1),
    ]

    static func opacity(latitudeDelta: Double, longitudeDelta: Double) -> Double {
        let span = min(latitudeDelta, longitudeDelta)
        guard let first = stops.first, let last = stops.last else { return 0 }
        if span <= first.span { return first.opacity }
        if span >= last.span { return last.opacity }
        for (low, high) in zip(stops, stops.dropFirst()) where span <= high.span {
            let t = (log(span) - log(low.span)) / (log(high.span) - log(low.span))
            return low.opacity + (high.opacity - low.opacity) * t
        }
        return last.opacity
    }

    /// The painting's centre in Mercator, where its annotation anchors.
    static var center: GeoPoint {
        GeoPoint(latitude(mercator: (mercator(north) + mercator(south)) / 2), (west + east) / 2)
    }

    /// Where the painting's annotation anchors for a visible region. MapKit
    /// drops an annotation whose coordinate is off screen, and draws one to
    /// the north beneath one to the south, so the anchor stays on screen,
    /// within the top sixteenth of the view (under the status bar and the
    /// controls), snapped to a grid a thirty-second of the span wide so it
    /// moves rarely while panning. The image is offset back into place.
    static func anchor(centerLatitude: Double, centerLongitude: Double, latitudeDelta: Double, longitudeDelta: Double) -> GeoPoint {
        let span = max(min(latitudeDelta, longitudeDelta), 1e-6)
        let step = pow(2, log2(span / 32).rounded(.down))
        let top = centerLatitude + latitudeDelta / 2
        return GeoPoint(((top - step) / step).rounded(.down) * step, (centerLongitude / step).rounded() * step)
    }

    /// The painting's centre relative to `anchor`, in points (y grows down).
    static func offset(from anchor: GeoPoint, centerLatitude: Double, latitudeDelta: Double, longitudeDelta: Double, mapSize: CGSize) -> CGSize {
        guard latitudeDelta > 0, longitudeDelta > 0 else { return .zero }
        let x = (center.longitude - anchor.longitude) / longitudeDelta * mapSize.width
        let visible = mercator(centerLatitude + latitudeDelta / 2) - mercator(centerLatitude - latitudeDelta / 2)
        let y = (mercator(anchor.latitude) - mercator(center.latitude)) / visible * mapSize.height
        return CGSize(width: x, height: y)
    }

    /// The painting's size in points for a visible region and map size.
    static func size(centerLatitude: Double, latitudeDelta: Double, longitudeDelta: Double, mapSize: CGSize) -> CGSize {
        guard latitudeDelta > 0, longitudeDelta > 0 else { return .zero }
        let width = (east - west) / longitudeDelta * mapSize.width
        let visible = mercator(centerLatitude + latitudeDelta / 2) - mercator(centerLatitude - latitudeDelta / 2)
        let height = (mercator(north) - mercator(south)) / visible * mapSize.height
        return CGSize(width: width, height: height)
    }

    private static func mercator(_ latitude: Double) -> Double {
        let radians = latitude * .pi / 180
        return log(tan(.pi / 4 + radians / 2))
    }

    private static func latitude(mercator y: Double) -> Double {
        (2 * atan(exp(y)) - .pi / 2) * 180 / .pi
    }
}
