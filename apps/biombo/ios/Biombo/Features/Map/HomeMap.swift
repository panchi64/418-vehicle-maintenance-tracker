import MapKit
import SwiftUI

/// The full-bleed home map. It draws only what `HomeDigest` already gated as
/// current: pins by layer shape (clustered per layer), outage areas by zoom
/// tier (§7), and the vantage dot, over Puerto Rico only. A collision pass
/// drops the lower-priority word where two would overlap. Under it all is
/// muted standard; Pintado lays the painted island over that at wide zoom.
struct HomeMap: View {
    let digest: HomeDigest
    let selectedID: String?
    @Binding var camera: MapCameraPosition
    let onSelect: (NearbyItem) -> Void
    /// Zoom to frame a point and span (cluster taps).
    let onFrame: (GeoPoint, Double) -> Void

    @State private var span = MKCoordinateSpan(latitudeDelta: HomeCamera.nearbySpan, longitudeDelta: HomeCamera.nearbySpan)
    @State private var size = CGSize.zero
    @State private var paintedViewport = PaintedViewport()
    @AppStorage(MapGround.storageKey) private var ground: MapGround = .painted
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit
    /// A map label's average character width; map words stop growing at xxLarge.
    @ScaledMetric(relativeTo: .caption) private var labelCharacterWidth = 7.0
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isPainted: Bool {
        ground.effective(isCrisis: digest.isCrisis, increasedContrast: contrast == .increased, reduceTransparency: reduceTransparency) == .painted
    }

    var body: some View {
        let content = MapContent(
            answers: digest.answers,
            areas: digest.areas,
            visibleLayers: digest.visibleLayers,
            tier: ZoomTier(latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
        )
        let marks = PinClusterer().marks(for: content.pins, latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
        let pins = marks.compactMap { if case .pin(let answer) = $0 { answer } else { nil } }
        let clusters = marks.compactMap { if case .cluster(let cluster) = $0 { cluster } else { nil } }
        let tags = pinTags(pins)
        // Crisis polygons carry no callouts: the official cards say the same thing (V2-Crisis, N7).
        let areaTags = digest.isCrisis ? [] : content.areas
        let labels = MapLabelPlacer().layout(
            marks: marks,
            areas: areaTags,
            vantage: digest.vantage,
            selectedID: selectedID,
            viewport: .init(latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta, width: size.width, height: size.height),
            labelWidths: labelWidths(tags)
        )

        // Pan and zoom only: the painting and the pins stay north-up.
        Map(position: $camera, bounds: HomeCamera.islandBounds, interactionModes: [.pan, .zoom]) {
            if isPainted {
                // Declared first and anchored near the top of the view, so every pin, tag and label draws above it.
                Annotation(coordinate: paintedViewport.anchor.coordinate, anchor: .center) {
                    PaintedIsland(viewport: paintedViewport)
                } label: {
                    EmptyView()
                }
                .annotationTitles(.hidden)
            }
            // Edges carry confidence as shape (§7): solid high, dashed medium, dotted low.
            ForEach(content.areas) { status in
                MapPolygon(coordinates: status.area.polygon.map(\.coordinate))
                    .foregroundStyle(Color(status.fill(status.confidence)))
                    .stroke(Color(status.stroke), style: status.confidence.edge)
                if let part = status.drawnExtension {
                    MapPolygon(coordinates: part.polygon.map(\.coordinate))
                        .foregroundStyle(Color(status.fill(status.extensionConfidence)))
                        .stroke(Color(status.stroke), style: status.extensionConfidence.edge)
                }
            }
            ForEach(areaTags) { status in
                // Moved by coordinate, not by offset, so the whole tag stays tappable.
                Annotation(coordinate: shifted(status.anchor, dy: labels.tagOffsets[status.id]).coordinate) {
                    AreaTag(status: status, part: .outline, now: digest.now) { onSelect(.area(status)) }
                } label: {
                    EmptyView()
                }
                if let part = status.drawnExtension {
                    Annotation(coordinate: part.anchor.coordinate) {
                        AreaTag(status: status, part: .extension, now: digest.now) { onSelect(.area(status)) }
                    } label: {
                        EmptyView()
                    }
                }
            }
            ForEach(content.counts) { count in
                Annotation(coordinate: count.anchor.coordinate) {
                    MunicipioCountTag(count: count)
                } label: {
                    EmptyView()
                }
            }
            ForEach(pins) { answer in
                Annotation(coordinate: shifted(answer.anchor, dy: labels.pinOffsets[answer.id]).coordinate, anchor: LayerPinShape(layer: answer.layer).tip) {
                    PinMark(
                        answer: answer,
                        tag: tags[answer.id] ?? nil,
                        now: digest.now,
                        isSelected: answer.id == selectedID,
                        showsLabel: !labels.hiddenLabels.contains(answer.id)
                    ) { onSelect(.place(answer)) }
                } label: {
                    EmptyView()
                }
            }
            ForEach(clusters) { cluster in
                Annotation(coordinate: cluster.anchor.coordinate, anchor: LayerPinShape(layer: cluster.layer).tip) {
                    ClusterMark(cluster: cluster) {
                        onFrame(cluster.anchor, max(cluster.span.latitude, cluster.span.longitude) * 2.5)
                    }
                } label: {
                    EmptyView()
                }
            }
            Annotation(coordinate: digest.vantage.coordinate) {
                VantageDot()
            } label: {
                EmptyView()
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {}
        .onMapCameraChange(frequency: .onEnd) { context in
            span = context.region.span
        }
        .onMapCameraChange(frequency: .continuous) { context in
            paintedViewport.update(region: context.region)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
            self.size = size
            paintedViewport.update(mapSize: size)
        }
    }

    /// A point moved by a few screen points at the current span.
    private func shifted(_ point: GeoPoint, dx: Double? = nil, dy: Double? = nil) -> GeoPoint {
        guard size.width > 0, size.height > 0 else { return point }
        return GeoPoint(
            point.latitude - (dy ?? 0) / size.height * span.latitudeDelta,
            point.longitude + (dx ?? 0) / size.width * span.longitudeDelta
        )
    }

    /// Each pin's tag: its answer, except in crisis, where prices step back
    /// (§8) and a station says whether it has gas, or nothing.
    private func pinTags(_ pins: [PlaceAnswer]) -> [String: LocalizedStringResource?] {
        let fuel = digest.availability.gasoline
        let stops = digest.isCrisis ? Dictionary((fuel.stops + fuel.without).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }) : [:]
        return Dictionary(uniqueKeysWithValues: pins.map { answer in
            guard digest.isCrisis, answer.layer == .gas else { return (answer.id, answer.valueText(unit: unit, locale: locale)) }
            return (answer.id, stops[answer.place.id].map { $0.value(for: .gasoline) })
        })
    }

    /// Each pin tag's width in points, from its words at the capped map text size.
    private func labelWidths(_ tags: [String: LocalizedStringResource?]) -> [String: Double] {
        tags.compactMapValues { tag in
            guard let words = tag else { return nil }
            return Double(words.string(in: locale).count) * labelCharacterWidth + 16
        }
    }
}

private extension AreaStatus {
    /// Fill strength follows confidence; the edge pattern says it too, so it
    /// never rests on colour alone.
    func fill(_ confidence: AreaConfidence?) -> ColorResource {
        switch (layer, confidence ?? .high) {
        case (.water, .low): .polygonWaterFillLow
        case (.water, .medium): .polygonWaterFillMedium
        case (.water, .high): .polygonWaterFillHigh
        case (.signal, .low): .polygonSignalFillLow
        case (.signal, .medium): .polygonSignalFillMedium
        case (.signal, .high): .polygonSignalFillHigh
        case (_, .low): .polygonPowerFillLow
        case (_, .medium): .polygonPowerFillMedium
        case (_, .high): .polygonPowerFillHigh
        }
    }

    var stroke: ColorResource {
        switch layer {
        case .water: .polygonWaterStroke
        case .signal: .polygonSignalStroke
        default: .polygonPowerStroke
        }
    }
}
