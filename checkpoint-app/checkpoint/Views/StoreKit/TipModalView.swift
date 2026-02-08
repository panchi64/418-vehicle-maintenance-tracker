//
//  TipModalView.swift
//  checkpoint
//
//  Post-action modal that appears after logging a service
//

import SwiftUI
import StoreKit

struct TipModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    private var storeManager: StoreManager { StoreManager.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("ENJOYING CHECKPOINT?")
                            .font(.brutalistHeading)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Help keep Checkpoint free for everyone.\nEvery tip unlocks an exclusive theme.")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Tip buttons in a horizontal row
                    HStack(spacing: Spacing.sm) {
                        ForEach(storeManager.tipProducts(), id: \.id) { product in
                            tipButton(for: product)
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)

                    // Dismiss
                    Button {
                        AnalyticsService.shared.capture(.tipModalDismissed)
                        dismiss()
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
                        AnalyticsService.shared.capture(.tipModalDismissed)
                        dismiss()
                    }
                    .toolbarButtonStyle()
                }
            }
        }
        .presentationDetents([.height(350)])
    }

    private func tipButton(for product: Product) -> some View {
        Button {
            Task {
                guard let productID = StoreManager.ProductID(rawValue: product.id) else { return }
                AnalyticsService.shared.capture(.purchaseAttempted(product: product.id))
                do {
                    let transaction = try await storeManager.purchase(productID)
                    if transaction != nil {
                        AnalyticsService.shared.capture(.purchaseSucceeded(product: product.id))
                        PurchaseSettings.shared.totalTipCount += 1
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
