import MapKit
import Observation
import SwiftUI

/// The camera numbers the painted island follows while the map moves. Kept
/// apart from `HomeMap`'s own state so continuous camera updates redraw
/// only the painting, never the pins or the label pass. It keeps the last
/// region, so a size change (first layout, rotation) redraws it too.
@Observable
final class PaintedViewport {
    private(set) var size: CGSize = .zero
    private(set) var opacity: Double = 0
    /// Where the painting's annotation sits; changes only when it must stay on screen.
    private(set) var anchor = PaintedGround.center
    /// The image's offset from `anchor`, in points.
    private(set) var offset: CGSize = .zero

    @ObservationIgnored private var region: MKCoordinateRegion?
    @ObservationIgnored private var mapSize: CGSize = .zero

    func update(region: MKCoordinateRegion) {
        self.region = region
        redraw()
    }

    func update(mapSize: CGSize) {
        self.mapSize = mapSize
        redraw()
    }

    private func redraw() {
        guard let region, mapSize.width > 0 else { return }
        let center = region.center
        let span = region.span
        let anchor = PaintedGround.anchor(
            centerLatitude: center.latitude, centerLongitude: center.longitude,
            latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta
        )
        if anchor != self.anchor { self.anchor = anchor }
        offset = PaintedGround.offset(
            from: anchor, centerLatitude: center.latitude,
            latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta, mapSize: mapSize
        )
        size = PaintedGround.size(
            centerLatitude: center.latitude,
            latitudeDelta: span.latitudeDelta,
            longitudeDelta: span.longitudeDelta,
            mapSize: mapSize
        )
        opacity = PaintedGround.opacity(latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
    }
}

/// The painted island (V2-Island), a geo-referenced raster laid on the map
/// at island and municipio zoom and gone at street zoom. It never takes a
/// touch, and never shows in Sencillo, crisis or high contrast.
struct PaintedIsland: View {
    let viewport: PaintedViewport

    var body: some View {
        if viewport.opacity > 0, viewport.size.width > 0 {
            Image(.paintedIsland)
                .resizable()
                .frame(width: viewport.size.width, height: viewport.size.height)
                .offset(viewport.offset)
                .opacity(viewport.opacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
