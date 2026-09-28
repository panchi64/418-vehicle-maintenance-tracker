import SwiftUI

/// The postcard line: a small painted plate beside the name in New York,
/// with an optional "where" line (V2-Station, V2-Nearby). The plate never
/// carries data. In crisis the name is SF and there is no plate (N18); with
/// Increase Contrast the asset catalog serves the line-only plate; at
/// accessibility sizes the plate steps aside so the name keeps the width.
struct PostcardStrip: View {
    let title: Text
    var subtitle: Text?
    var motif: PlateMotif?

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: Spacing.s3) {
            if let motif, !theme.isCrisis, !dynamicTypeSize.isAccessibilitySize {
                PostcardPlate(motif: motif)
                    .frame(width: Size.plateStripWidth, height: Size.plateStrip)
            }
            VStack(alignment: .leading, spacing: 2) {
                title
                    .placeTitle()
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    subtitle
                        .textRole(.subheadline)
                        .foregroundStyle(Color(.ink2))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// A place's name as a title: New York in ink-serif, or SF in ink during crisis (N18).
    func placeTitle() -> some View {
        modifier(PlaceTitle())
    }
}

private struct PlaceTitle: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .textRole(theme.isCrisis ? .headline : .sectionTitle)
            .foregroundStyle(Color(theme.isCrisis ? .ink : .inkSerif))
    }
}

/// A painted plate from `Art/Postal`, clipped and edged by the app.
struct PostcardPlate: View {
    let motif: PlateMotif

    var body: some View {
        Image(motif.image)
            .resizable()
            .scaledToFill()
            .clipShape(.rect(cornerRadius: Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: Radius.medium).strokeBorder(Color(.plateEdge), lineWidth: 1))
            .accessibilityHidden(true)
    }
}

/// Which plate a place or barrio shows (direction §1.1): a category plate
/// for places, a landscape for barrios.
enum PlateMotif: Hashable, Sendable {
    case station
    case charger
    case business
    case water
    case road
    case mountain
    case coast
    case city

    var image: ImageResource {
        switch self {
        case .station: .plateGasolinera
        case .charger: .plateCargador
        case .business: .plateColmado
        case .water: .plateAgua
        case .road: .plateCarretera
        case .mountain: .plateBarrioMontana
        case .coast: .plateBarrioCosta
        case .city: .plateBarrioCiudad
        }
    }

    /// A barrio's landscape by region.
    init(region: Region) {
        switch region {
        case .metro: self = .city
        case .west, .north, .south, .east: self = .coast
        case .central: self = .mountain
        }
    }
}
