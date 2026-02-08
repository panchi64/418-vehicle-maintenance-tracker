//
//  TipJarView.swift
//  checkpoint
//
//  Tip jar view with gacha-style rare theme unlocks
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    @Environment(AppState.self) private var appState

    private var storeManager: StoreManager { StoreManager.shared }

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("SUPPORT CHECKPOINT")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(2)

                        Text("Help keep Checkpoint free and actively developed. Every tip unlocks an exclusive rare theme.")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    // Tip tiers
                    VStack(spacing: Spacing.md) {
                        ForEach(storeManager.tipProducts(), id: \.id) { product in
                            TipCard(product: product) {
                                await purchaseTip(product)
                            }
                        }
                    }

                    // All collected state
                    if ThemeManager.shared.allThemes.filter({ $0.tier == .rare }).allSatisfy({ ThemeManager.shared.isOwned($0) }) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                            Text("You've collected all rare themes!")
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.top, Spacing.sm)
                    }

                    Spacer()
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
        }
        .navigationTitle("Tip Jar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func purchaseTip(_ product: Product) async {
        guard let productID = StoreManager.ProductID(rawValue: product.id) else { return }

        AnalyticsService.shared.capture(.purchaseAttempted(product: product.id))

        do {
            let transaction = try await storeManager.purchase(productID)
            if transaction != nil {
                AnalyticsService.shared.capture(.purchaseSucceeded(product: product.id))
                PurchaseSettings.shared.totalTipCount += 1

                // Gacha: unlock random rare theme
                if let theme = ThemeManager.shared.unlockRandomRareTheme() {
                    AnalyticsService.shared.capture(.themeUnlocked(themeID: theme.id, tier: "rare"))
                    appState.unlockedTheme = theme
                }
            }
        } catch {
            AnalyticsService.shared.capture(.purchaseFailed(product: product.id, error: error.localizedDescription))
        }
    }
}

// MARK: - Tip Card

private struct TipCard: View {
    let product: Product
    let onPurchase: () async -> Void

    @State private var isPurchasing = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                Text(product.description)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

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
                        .frame(width: 70)
                } else {
                    Text(product.displayPrice)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.surfaceInstrument)
                        .frame(width: 70)
                }
            }
            .buttonStyle(.primary)
            .frame(width: 90, height: 40)
            .disabled(isPurchasing)
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }
}
