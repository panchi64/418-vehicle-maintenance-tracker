//
//  TipJarView.swift
//  checkpoint
//
//  Tip jar view with gacha-style rare theme unlocks
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    // Local sheet state so ThemeRevealView stacks on top of the parent
    // Settings sheet that contains us. Routing through the root
    // .sheet(item:) in ContentView is rejected while Settings is up.
    @State private var unlockedTheme: ThemeDefinition?

    private var storeManager: StoreManager { StoreManager.shared }

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(L10n.tipSupportCheckpoint)
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .textCase(.uppercase)
                            .tracking(2)
                            .accessibilityAddTraits(.isHeader)

                        Text(L10n.tipJarBody)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    // Tip tiers
                    VStack(spacing: Spacing.md) {
                        #if DEBUG
                        if storeManager.tipProducts().isEmpty {
                            ForEach(TipTier.debugOptions, id: \.productID) { option in
                                TipCard(name: option.label, description: nil, price: option.price) {
                                    await debugPurchaseTip(option.productID)
                                }
                            }
                        } else {
                            productCards
                        }
                        #else
                        productCards
                        #endif
                    }

                    // Collection progress
                    let progress = RareThemeProgress.current
                    if progress.total > 0 {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: progress.isComplete ? "checkmark.seal.fill" : "square.grid.2x2")
                                .font(.caption2)
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(progress.text)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)
                        }
                        .padding(.top, Spacing.sm)
                    }
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
        }
        .navigationTitle(L10n.tipJarTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $unlockedTheme) { theme in
            ThemeRevealView(theme: theme)
        }
    }

    private var productCards: some View {
        ForEach(storeManager.tipProducts(), id: \.id) { product in
            TipCard(name: TipTier.label(for: product), description: product.description, price: product.displayPrice) {
                await purchaseTip(product)
            }
        }
    }

    #if DEBUG
    private func debugPurchaseTip(_ productID: StoreManager.ProductID) async {
        await storeManager.simulatePurchase(productID)
        PurchaseSettings.shared.recordTip()
        if let theme = ThemeManager.shared.unlockRandomRareTheme() {
            AnalyticsService.shared.capture(.themeUnlocked(themeID: theme.id, tier: "rare"))
            unlockedTheme = theme
        }
    }
    #endif

    private func purchaseTip(_ product: Product) async {
        guard let productID = StoreManager.ProductID(rawValue: product.id) else { return }

        AnalyticsService.shared.capture(.purchaseAttempted(product: product.id))

        do {
            let transaction = try await storeManager.purchase(productID)
            if transaction != nil {
                AnalyticsService.shared.capture(.purchaseSucceeded(product: product.id))
                PurchaseSettings.shared.recordTip()

                // Gacha: unlock random rare theme
                if let theme = ThemeManager.shared.unlockRandomRareTheme() {
                    AnalyticsService.shared.capture(.themeUnlocked(themeID: theme.id, tier: "rare"))
                    unlockedTheme = theme
                }
            }
        } catch {
            AnalyticsService.shared.capture(.purchaseFailed(product: product.id, error: error.localizedDescription))
        }
    }
}

// MARK: - Tip Card

private struct TipCard: View {
    let name: String
    let description: String?
    let price: String
    let onPurchase: () async -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPurchasing = false

    /// Name beside price at standard sizes; stacked at accessibility sizes so
    /// the price button gets the full width instead of clipping.
    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.md))
            : AnyLayout(HStackLayout(spacing: Spacing.md))
    }

    var body: some View {
        layout {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                if let description {
                    Text(description)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isPurchasing = true
                Task {
                    await onPurchase()
                    isPurchasing = false
                }
            } label: {
                if isPurchasing {
                    ProgressView()
                        .tint(Theme.surfaceInstrument)
                } else {
                    Text(price)
                }
            }
            .buttonStyle(.primary)
            .frame(minWidth: 90)
            .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: false)
            .disabled(isPurchasing)
            .accessibilityLabel(isPurchasing ? L10n.tipPurchasing : L10n.tipPurchaseLabel(name: name, price: price))
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }
}
