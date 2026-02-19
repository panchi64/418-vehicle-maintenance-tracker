//
//  TipModalView.swift
//  checkpoint
//
//  Post-action modal that appears after completing maintenance actions.
//  Shows personalized stats about how the app has helped the user,
//  with progressive backoff and cooldown to stay non-intrusive.
//

import SwiftUI
import SwiftData
import StoreKit

struct TipModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query private var serviceLogs: [ServiceLog]
    @Query private var vehicles: [Vehicle]
    @Query private var services: [Service]

    private var storeManager: StoreManager { StoreManager.shared }

    private var stats: TipPromptStats {
        TipPromptStats(
            servicesLogged: serviceLogs.count,
            servicesTracked: services.count,
            vehicleCount: vehicles.count,
            totalCost: serviceLogs.compactMap(\.cost).reduce(Decimal.zero, +),
            hasTippedBefore: PurchaseSettings.shared.totalTipCount > 0
        )
    }

    private var promptContent: TipPromptContent {
        TipPromptContent.select(from: stats)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    // Stats-driven header
                    VStack(spacing: Spacing.sm) {
                        Text(promptContent.headline)
                            .font(.brutalistHeading)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(promptContent.body)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        Text("Every tip also unlocks a rare theme.")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .padding(.top, Spacing.xs)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)

                    // Tip buttons in a horizontal row
                    HStack(spacing: Spacing.sm) {
                        #if DEBUG
                        if storeManager.tipProducts().isEmpty {
                            debugTipSmall
                            debugTipMedium
                            debugTipLarge
                        } else {
                            ForEach(storeManager.tipProducts(), id: \.id) { product in
                                tipButton(for: product)
                            }
                        }
                        #else
                        ForEach(storeManager.tipProducts(), id: \.id) { product in
                            tipButton(for: product)
                        }
                        #endif
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)

                    // Dismiss
                    Button {
                        handleDismiss()
                    } label: {
                        Text("Not now")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handleDismiss()
                    }
                    .toolbarButtonStyle()
                }
            }
        }
        .presentationDetents([.height(380)])
    }

    // MARK: - Actions

    private func handleDismiss() {
        let dismissCount = PurchaseSettings.shared.tipPromptDismissCount
        PurchaseSettings.shared.recordTipPromptDismiss()
        AnalyticsService.shared.capture(.tipModalDismissed(dismissCount: dismissCount + 1))
        dismiss()
    }

    private func handleSuccessfulTip() {
        PurchaseSettings.shared.recordTip()
    }

    // MARK: - Debug Buttons

    #if DEBUG
    private func debugTipButton(label: String, price: String, productID: StoreManager.ProductID) -> some View {
        Button {
            Task {
                await storeManager.simulatePurchase(productID)
                handleSuccessfulTip()
                dismiss()
                if let theme = ThemeManager.shared.unlockRandomRareTheme() {
                    AnalyticsService.shared.capture(.themeUnlocked(themeID: theme.id, tier: "rare"))
                    try? await Task.sleep(for: .seconds(0.5))
                    appState.unlockedTheme = theme
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(price)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.surfaceInstrument)
                Text(label)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.surfaceInstrument.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(.primary)
    }

    private var debugTipSmall: some View {
        debugTipButton(label: "Small", price: "$1.99", productID: .tipSmall)
    }

    private var debugTipMedium: some View {
        debugTipButton(label: "Medium", price: "$4.99", productID: .tipMedium)
    }

    private var debugTipLarge: some View {
        debugTipButton(label: "Large", price: "$9.99", productID: .tipLarge)
    }
    #endif

    // MARK: - Tip Button

    private func tipButton(for product: Product) -> some View {
        Button {
            Task {
                guard let productID = StoreManager.ProductID(rawValue: product.id) else { return }
                AnalyticsService.shared.capture(.purchaseAttempted(product: product.id))
                do {
                    let transaction = try await storeManager.purchase(productID)
                    if transaction != nil {
                        AnalyticsService.shared.capture(.purchaseSucceeded(product: product.id))
                        handleSuccessfulTip()
                        dismiss()
                        if let theme = ThemeManager.shared.unlockRandomRareTheme() {
                            AnalyticsService.shared.capture(.themeUnlocked(themeID: theme.id, tier: "rare"))
                            // Small delay to let the tip modal dismiss first
                            try? await Task.sleep(for: .seconds(0.5))
                            appState.unlockedTheme = theme
                        }
                    }
                } catch {
                    AnalyticsService.shared.capture(.purchaseFailed(product: product.id, error: error.localizedDescription))
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(product.displayPrice)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.surfaceInstrument)
                Text(product.displayName.replacingOccurrences(of: " Tip", with: ""))
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.surfaceInstrument.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(.primary)
    }
}

// MARK: - Stats

/// Aggregated user stats used to personalize the tip prompt.
struct TipPromptStats {
    let servicesLogged: Int
    let servicesTracked: Int
    let vehicleCount: Int
    let totalCost: Decimal
    let hasTippedBefore: Bool

    var formattedCost: String? {
        guard totalCost > 0 else { return nil }
        return Formatters.currency.string(from: totalCost as NSDecimalNumber)
    }
}

// MARK: - Tip Prompt Content

/// Builds personalized, stats-driven messages for the tip prompt.
/// Instead of generic "enjoying the app?" copy, it reflects what the user
/// has actually accomplished with Checkpoint.
struct TipPromptContent {
    let headline: String
    let body: String

    static func select(from stats: TipPromptStats) -> TipPromptContent {
        if stats.hasTippedBefore {
            return returningTipper(stats: stats)
        }
        return firstTime(stats: stats)
    }

    // MARK: - First-Time Prompt

    private static func firstTime(stats: TipPromptStats) -> TipPromptContent {
        let headline = buildHeadline(stats: stats)
        let body = buildBody(stats: stats)
        return TipPromptContent(headline: headline, body: body)
    }

    private static func buildHeadline(stats: TipPromptStats) -> String {
        // Lead with the most impressive stat the user has
        if let cost = stats.formattedCost {
            return "\(cost) TRACKED"
        }
        if stats.servicesLogged >= 5 {
            return "\(stats.servicesLogged) SERVICES LOGGED"
        }
        if stats.servicesTracked >= 3 {
            return "\(stats.servicesTracked) SERVICES TRACKED"
        }
        if stats.vehicleCount > 1 {
            return "\(stats.vehicleCount) VEHICLES MANAGED"
        }
        return "YOUR MAINTENANCE, HANDLED"
    }

    private static func buildBody(stats: TipPromptStats) -> String {
        var parts: [String] = []

        if stats.vehicleCount > 1 {
            parts.append("You're managing \(stats.vehicleCount) vehicles")
        }

        if stats.servicesLogged > 0 && stats.servicesTracked > 0 {
            parts.append("\(stats.servicesLogged) logged, \(stats.servicesTracked) on the radar")
        } else if stats.servicesTracked > 0 {
            parts.append("\(stats.servicesTracked) services on the radar")
        } else if stats.servicesLogged > 0 {
            parts.append("\(stats.servicesLogged) services logged")
        }

        let statLine: String
        if parts.isEmpty {
            statLine = "You're building a solid maintenance history."
        } else {
            statLine = parts.joined(separator: " with ") + "."
        }

        return statLine + "\nCheckpoint is made by one dev — a tip helps keep it free."
    }

    // MARK: - Returning Tipper Prompt

    private static func returningTipper(stats: TipPromptStats) -> TipPromptContent {
        let headline: String
        if let cost = stats.formattedCost {
            headline = "\(cost) AND COUNTING"
        } else if stats.servicesLogged >= 5 {
            headline = "\(stats.servicesLogged) SERVICES AND COUNTING"
        } else {
            headline = "STILL GOING STRONG"
        }

        return TipPromptContent(
            headline: headline,
            body: "Your support keeps Checkpoint improving.\nAnother tip unlocks another rare theme."
        )
    }
}
