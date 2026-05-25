import SwiftUI
import CoreLocation
import DesignKit

struct StationRow: View {
    @Environment(\.theme) private var theme
    let price: CachedFuelPrice
    let userLocation: CLLocation?

    var body: some View {
        HStack(alignment: .top, spacing: DKSpacing.md) {
            VStack(alignment: .leading, spacing: DKSpacing.xs) {
                Text(price.brand ?? price.stationName)
                    .font(theme.font(.headline, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .textCase(.uppercase)
                    .tracking(1.5)

                if let municipality = price.municipality {
                    Text(municipality)
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }

                FreshnessIndicator(freshness: price.freshness, source: price.source)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: DKSpacing.xs) {
                if let regular = price.regularPrice {
                    Text(Formatters.priceString(regular))
                        .font(theme.font(.title2, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                }

                if let distance = distanceText {
                    Text(distance)
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.textTertiary)
                        .tracking(1)
                }
            }
        }
        .padding(.horizontal, DKSpacing.md)
        .padding(.vertical, DKSpacing.sm)
    }

    private var distanceText: String? {
        guard let userLocation else { return nil }
        let meters = CLLocation(latitude: price.latitude, longitude: price.longitude)
            .distance(from: userLocation)
        return Formatters.distanceString(meters: meters)
    }
}
