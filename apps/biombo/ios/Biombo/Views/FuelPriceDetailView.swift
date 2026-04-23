import SwiftUI
import SwiftData
import DesignKit
import Localization

struct FuelPriceDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    let price: CachedFuelPrice

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DKSpacing.lg) {
                header

                sectionHeader("detail.prices")
                ForEach(price.gradeEntries) { entry in
                    DesignKit.DataRow(
                        label: gradeLabel(entry.id),
                        value: Formatters.priceString(entry.price),
                        labelColor: theme.textTertiary,
                        valueColor: theme.textPrimary,
                        labelFont: theme.font(.caption, weight: .semibold),
                        valueFont: theme.font(.title2, weight: .bold)
                    )
                }

                if price.hasDacoDelta {
                    sectionHeader("detail.daco_delta")
                    ForEach(price.gradeEntries) { entry in
                        if let delta = entry.delta {
                            DesignKit.DataRow(
                                label: gradeLabel(entry.id),
                                value: deltaString(delta),
                                labelColor: theme.textTertiary,
                                valueColor: theme.textPrimary,
                                labelFont: theme.font(.caption, weight: .semibold),
                                valueFont: theme.font(.body, weight: .bold)
                            )
                        }
                    }
                }

                sectionHeader("detail.history")
                PriceTrendChart(stationId: price.recordID)
                    .frame(height: 160)
            }
            .padding(DKSpacing.md)
        }
        .background(theme.backgroundPrimary.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DKSpacing.xs) {
            Text(price.brand ?? price.stationName)
                .font(theme.font(.largeTitle, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .textCase(.uppercase)
                .tracking(2)

            if let municipality = price.municipality {
                Text(municipality)
                    .font(theme.font(.subheadline))
                    .foregroundStyle(theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.5)
            }

            FreshnessIndicator(freshness: price.freshness, source: price.source)
                .padding(.top, DKSpacing.xs)
        }
    }

    private func sectionHeader(_ title: String.LocalizationValue) -> some View {
        DesignKit.SectionHeader(
            title: String(localized: title),
            labelColor: theme.textTertiary,
            dividerColor: theme.gridLine,
            dividerHeight: 2,
            labelFont: theme.font(.caption, weight: .semibold)
        )
    }

    private func gradeLabel(_ grade: CachedFuelPrice.GradeEntry.Grade) -> String {
        switch grade {
        case .regular: return L10n.Shared.FuelGrade.regular
        case .premium: return L10n.Shared.FuelGrade.premium
        case .diesel:  return L10n.Shared.FuelGrade.diesel
        }
    }

    private func deltaString(_ delta: Double) -> String {
        let sign = delta >= 0 ? "+" : "−"
        return sign + Formatters.priceString(abs(delta))
    }
}
