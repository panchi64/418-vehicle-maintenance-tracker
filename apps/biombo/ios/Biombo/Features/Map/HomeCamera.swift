import MapKit
import SwiftUI

/// Camera framings the home screen moves between.
enum HomeCamera {
    /// Wide enough to show the nearby answers around the vantage point (municipio zoom).
    static let nearbySpan = 0.35
    /// A place or search result, at street zoom.
    static let placeSpan = 0.05
    /// A municipio from search.
    static let municipioSpan = 0.15

    /// How far the centre drops below `point`, as a share of the span, so the
    /// point sits in the map area the sheet leaves open.
    static let sheetOffset = 0.35

    /// The camera stays over Puerto Rico, Vieques and Culebra included: close
    /// enough to read a street, far enough to see the whole island, never
    /// out over open sea.
    static let islandBounds = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 18.2, longitude: -66.4),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 2.4)
        ),
        minimumDistance: 400,
        maximumDistance: 650_000
    )

    static func around(_ point: GeoPoint, span: Double) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: GeoPoint(point.latitude - span * sheetOffset, point.longitude).coordinate,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        ))
    }
}
