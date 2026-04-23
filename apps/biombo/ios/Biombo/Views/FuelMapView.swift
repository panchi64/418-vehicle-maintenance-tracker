import SwiftUI
import SwiftData
import MapKit
import DesignKit

struct FuelMapView: View {
    @Environment(\.theme) private var theme
    @Environment(BiomboAppState.self) private var appState

    @Query(
        filter: #Predicate<CachedFuelPrice> { $0.flagCount < 3 },
        sort: \CachedFuelPrice.reportedAt,
        order: .reverse
    )
    private var cachedPrices: [CachedFuelPrice]

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var presentedStationId: String?

    var body: some View {
        Map(position: $cameraPosition, selection: $presentedStationId) {
            ForEach(visiblePrices) { price in
                Annotation(
                    price.stationName,
                    coordinate: CLLocationCoordinate2D(latitude: price.latitude, longitude: price.longitude),
                    anchor: .bottom
                ) {
                    PriceAnnotationView(price: price)
                }
                .tag(price.recordID)
            }
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .bottomTrailing) {
            submitButton.padding(DKSpacing.md)
        }
        .sheet(item: selectedStation) { price in
            FuelPriceDetailView(price: price)
        }
    }

    private var visiblePrices: [CachedFuelPrice] {
        cachedPrices.filter { !$0.isExpired }
    }

    private var selectedStation: Binding<CachedFuelPrice?> {
        Binding(
            get: { cachedPrices.first(where: { $0.recordID == presentedStationId }) },
            set: { presentedStationId = $0?.recordID }
        )
    }

    private var submitButton: some View {
        Button {
            appState.showingSubmitSheet = true
        } label: {
            Label("action.submit", systemImage: "camera.fill")
                .font(theme.font(.caption, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(theme.backgroundPrimary)
                .padding(.horizontal, DKSpacing.md)
                .padding(.vertical, DKSpacing.sm)
                .background(theme.accent)
        }
        .buttonStyle(.plain)
        .brutalistBorder(color: theme.backgroundPrimary, lineWidth: 2)
    }
}
