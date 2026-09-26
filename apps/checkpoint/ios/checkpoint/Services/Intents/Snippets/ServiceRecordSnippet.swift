//
//  ServiceRecordSnippet.swift
//  checkpoint
//
//  What Mark Done and Log Service show before they write: the services and
//  every value Siri heard, so a misheard odometer or cost is caught on screen
//  before it becomes history. Speech has no form to read back — this is it.
//
//  A Readout: the services are the one primary element (first, and the only
//  text in the emphasis weight); the heard values follow as label/value rows,
//  and only the ones actually said appear, except the odometer, which always
//  shows because it is written either way.
//

import AppIntents
import SwiftUI

struct ServiceRecordSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Service Record"
    static let isDiscoverable = false

    @Parameter(title: "Services")
    var serviceNames: [String]

    @Parameter(title: "Vehicle")
    var vehicleName: String

    @Parameter(title: "Date")
    var date: Date

    /// Stored miles — the reading that will be written.
    @Parameter(title: "Mileage")
    var mileage: Int

    @Parameter(title: "Cost")
    var cost: IntentCurrencyAmount?

    @Parameter(title: "Shop")
    var shop: String?

    init() {}

    init(serviceNames: [String], vehicleName: String, date: Date, mileage: Int, cost: IntentCurrencyAmount?, shop: String?) {
        self.serviceNames = serviceNames
        self.vehicleName = vehicleName
        self.date = date
        self.mileage = mileage
        self.cost = cost
        self.shop = shop
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        .result(view: ServiceRecordSnippetView(
            services: SpokenValue.list(serviceNames),
            vehicleName: vehicleName,
            date: SpokenValue.date(date),
            mileage: SpokenValue.mileage(mileage),
            cost: cost.map { SpokenValue.money($0.amount) },
            shop: shop
        ))
    }
}

struct ServiceRecordSnippetView: View {
    let services: String
    let vehicleName: String
    let date: String
    let mileage: String
    let cost: String?
    let shop: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(services)
                    .font(.brutalistBodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
                Text(vehicleName)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                BrutalistDataRow(label: L10n.siriSnippetDate, value: date)
                BrutalistDataRow(label: L10n.siriSnippetOdometer, value: mileage)
                if let cost {
                    BrutalistDataRow(label: L10n.siriSnippetCost, value: cost)
                }
                if let shop, !shop.isEmpty {
                    BrutalistDataRow(label: L10n.siriSnippetShop, value: shop)
                }
            }
        }
        .padding(Spacing.md)
    }
}
