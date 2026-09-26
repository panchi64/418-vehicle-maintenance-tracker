//
//  SpendingSummaryIntent.swift
//  checkpoint
//
//  "How much have I spent on the Civic this year?" The Costs tab's number for
//  a period, optionally one category, from `CostAnalyticsService` — so Siri
//  can never quote a figure the Costs tab disagrees with. Spoken as one
//  sentence over a small card with the per-category split.
//

import AppIntents
import SwiftData
import SwiftUI

struct SpendingSummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Spending Summary"
    static let description = IntentDescription("Hear how much you've spent on a vehicle over a period, optionally for one category")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    @Parameter(title: "Period", default: .yearToDate)
    var period: CostPeriod

    @Parameter(title: "Category", description: "Leave empty for every category")
    var category: CostCategory?

    static var parameterSummary: some ParameterSummary {
        Summary("Spending on \(\.$vehicle) for \(\.$period)") {
            \.$category
        }
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentCurrencyAmount> & ProvidesDialog & ShowsSnippetView {
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: container.mainContext)
        let summary = CostAnalyticsService.summary(logs: vehicle.serviceLogs ?? [], period: period, category: category)
        let total = SpokenValue.money(summary.total)
        return .result(
            value: IntentCurrencyAmount.stored(summary.total),
            dialog: IntentDialog(stringLiteral: Self.answer(summary, total: total, vehicle: vehicle)),
            view: SpendingSnippetView(
                total: total,
                caption: L10n.siriSnippetCaption(vehicle: vehicle.displayName, period: summary.period.fullName),
                breakdown: category == nil ? Self.breakdown(summary) : [],
                expenseCount: summary.expenseCount
            )
        )
    }

    @MainActor
    static func answer(_ summary: CostSummary, total: String, vehicle: Vehicle) -> String {
        guard let category = summary.category else {
            return L10n.siriSpending(amount: total, vehicle: vehicle.displayName, period: summary.period.fullName)
        }
        return L10n.siriSpending(
            amount: total,
            vehicle: vehicle.displayName,
            category: category.displayName,
            period: summary.period.fullName
        )
    }

    /// The period's spend per category, in the Costs tab's category order,
    /// with uncategorized last. Nothing-spent buckets are left out.
    @MainActor
    static func breakdown(_ summary: CostSummary) -> [(label: String, amount: String)] {
        let buckets = CostCategory.allCases.map(CostBucket.category) + [.uncategorized]
        return buckets.compactMap { bucket in
            guard let amount = summary.totalsByBucket[bucket], amount > 0 else { return nil }
            return (bucket.displayName, SpokenValue.money(amount))
        }
    }
}
