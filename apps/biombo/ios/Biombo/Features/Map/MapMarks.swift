import MapKit
import SwiftUI

extension GeoPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension View {
    /// Map words stop growing at xxLarge so they never slide under the
    /// controls or each other; the sheet carries the accessibility sizes.
    func mapTextSize() -> some View {
        dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

/// A place's pin with its tag beside it ("$0.99", "Inundada", in crisis "Hay
/// gasolina"). The tag is an overlay so the pin's tip, not the tag, anchors
/// to the map. Where it would cover another, the collision pass drops it;
/// the pin and its VoiceOver label still say the answer.
struct PinMark: View {
    let answer: PlaceAnswer
    /// The words beside the pin; nil draws the pin alone.
    let tag: LocalizedStringResource?
    let now: Date
    let isSelected: Bool
    var showsLabel = true
    let action: () -> Void

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        Button(action: action) {
            LayerPin(layer: answer.layer, glyph: answer.glyph, size: Size.mapPin, hasHalo: true, isSelected: isSelected)
                .overlay(alignment: .leading) {
                    if let tag, showsLabel || isSelected {
                        MapTag(text: tag)
                            .offset(x: Size.mapPin + 2)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(PinVoice.label(answer, now: now, unit: unit, locale: locale)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Several same-layer pins as one counted mark: the layer's shape plus the count.
struct ClusterMark: View {
    let cluster: PinCluster
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LayerPin(layer: cluster.layer, size: Size.mapPin, hasHalo: true)
                .overlay(alignment: .topTrailing) {
                    Text(cluster.members.count, format: .number)
                        .textRole(.viz)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(.ink))
                        .padding(.horizontal, 5)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Color(.paperRaised), in: .capsule)
                        .overlay(Capsule().strokeBorder(Color(.pinContour), lineWidth: Size.contour))
                        .offset(x: 8, y: -8)
                        .mapTextSize()
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(cluster.layer.countText(cluster.members.count)))
        .accessibilityHint(Text("Acerca el mapa para verlos", comment: "VoiceOver hint on a cluster of pins: activating zooms in"))
    }
}

/// An outage area's source and word on the map ("LUMA · Sin luz",
/// "Vecinos · Sin luz"), symbol plus words (§7, V2-Outage). An official
/// area with neighbours past its outline gets one tag per part.
struct AreaTag: View {
    enum Part {
        case outline
        /// The neighbours-only part past an official outline.
        case `extension`
    }

    let status: AreaStatus
    let part: Part
    let now: Date
    let action: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            MapTag(text: text, symbol: voice.symbol)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private var voice: SourceMix.Voice {
        if part == .outline, case .official(let agency) = status.label { .official(agency) } else { .neighbours }
    }

    private var text: LocalizedStringResource {
        switch voice {
        case .official(let agency): LocalizedStringResource("\(agency.displayName) · \(status.word)", comment: "Map tag on an official outage area: the agency, then the status, e.g. 'LUMA · Sin luz'")
        case .neighbours: LocalizedStringResource("Vecinos · \(status.word)", comment: "Map tag on a community outage area: neighbours, then the status")
        }
    }

    private var label: LocalizedStringResource {
        part == .extension
            ? LocalizedStringResource("\(status.sentence). Solo según vecinos, fuera del área oficial.", comment: "VoiceOver for the neighbours-only part past an official outage area")
            : PinVoice.label(status, now: now, locale: locale)
    }
}

extension AreaConfidence? {
    /// The polygon edge: solid for high confidence, dashed for medium,
    /// dotted for low, so confidence never rests on colour (§7).
    var edge: StrokeStyle {
        switch self ?? .high {
        case .high: StrokeStyle(lineWidth: 2)
        case .medium: StrokeStyle(lineWidth: 2, dash: [7, 4])
        case .low: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [0.5, 5])
        }
    }
}

/// Island zoom: "Caguas · 1 área sin luz", per municipio, instead of polygons.
struct MunicipioCountTag: View {
    let count: MunicipioCount

    var body: some View {
        HStack(spacing: Spacing.s1) {
            LayerPin(layer: count.layer, glyph: count.layer == .power ? ReportKind.noPower.glyph : nil, size: Size.listPin)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: count.municipio)
                    .textRole(.caption)
                    .fontWeight(.semibold)
                Text(count.layer.areaCountText(count.count))
                    .textRole(.caption)
            }
            .foregroundStyle(Color(.ink))
        }
        .padding(.leading, 4)
        .padding(.trailing, Spacing.s2)
        .padding(.vertical, 3)
        .background(Color(.paperRaised), in: .capsule)
        .overlay(Capsule().strokeBorder(Color(.pinContour), lineWidth: Size.contour))
        .mapTextSize()
        .accessibilityElement(children: .combine)
    }
}

/// The small paper tag used beside pins and on areas.
struct MapTag: View {
    let text: LocalizedStringResource
    var symbol: String?

    var body: some View {
        HStack(spacing: 3) {
            if let symbol {
                Image(systemName: symbol)
                    .accessibilityHidden(true)
            }
            Text(text)
        }
        .textRole(.viz)
        .fontWeight(.semibold)
        .foregroundStyle(Color(.ink))
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(.paperRaised), in: .capsule)
        .overlay(Capsule().strokeBorder(Color(.pinContour), lineWidth: Size.contour))
        .mapTextSize()
    }
}

/// Where "cerca" is measured from.
struct VantageDot: View {
    var body: some View {
        Circle()
            .fill(.tint)
            .frame(width: 18, height: 18)
            .overlay(Circle().strokeBorder(Color(.paperRaised), lineWidth: 3))
            .background(Circle().fill(.tint.opacity(0.18)).frame(width: 38, height: 38))
            .accessibilityElement()
            .accessibilityLabel(Text("Tu ubicación de muestra", comment: "VoiceOver: the sample location the app measures 'near you' from"))
    }
}
