import SwiftUI
import SwiftData
import CoreLocation
import DesignKit

struct FuelListView: View {
    @Environment(\.theme) private var theme
    @Environment(BiomboAppState.self) private var appState

    @Query(
        filter: #Predicate<CachedFuelPrice> { $0.flagCount < 3 },
        sort: \CachedFuelPrice.reportedAt,
        order: .reverse
    )
    private var cachedPrices: [CachedFuelPrice]

    @State private var selectedStation: CachedFuelPrice?
    private let locationService = LocationService.shared

    var body: some View {
        listContent
        .overlay(alignment: .bottomTrailing) {
            Button {
                appState.showingSubmitSheet = true
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(theme.backgroundPrimary)
                    .frame(width: 56, height: 56)
                    .background(theme.accent)
            }
            .buttonStyle(.plain)
            .brutalistBorder(color: theme.backgroundPrimary, lineWidth: 2)
            .padding(DKSpacing.md)
        }
        .sheet(item: $selectedStation) { price in
            FuelPriceDetailView(price: price)
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if sortedPrices.isEmpty {
            EmptyStateView(
                code: "// STATUS: AWAITING DATA",
                title: "list.empty.title",
                message: "list.empty.body"
            )
            .accessibilityIdentifier("list.emptyState")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sortedPrices, id: \.recordID) { price in
                        Button {
                            selectedStation = price
                        } label: {
                            StationRow(price: price, userLocation: locationService.currentLocation)
                        }
                        .buttonStyle(.plain)

                        Rectangle()
                            .fill(theme.borderSubtle)
                            .frame(height: 2)
                    }
                }
                .padding(.vertical, DKSpacing.sm)
            }
        }
    }

    private var sortedPrices: [CachedFuelPrice] {
        let visible = cachedPrices.filter { !$0.isExpired }
        guard let user = locationService.currentLocation else { return visible }
        return visible
            .map { ($0, CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: user)) }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }
}
