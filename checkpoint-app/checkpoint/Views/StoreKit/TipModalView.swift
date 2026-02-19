//
//  TipModalView.swift
//  checkpoint
//
//  Post-action modal that appears after completing maintenance actions.
//  Uses context-aware messaging and progressive backoff to stay non-intrusive.
//

import SwiftUI
import StoreKit

struct TipModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    private var storeManager: StoreManager { StoreManager.shared }

    private var promptContent: TipPromptContent {
        TipPromptContent.select(
            tipCount: PurchaseSettings.shared.totalTipCount,
            dismissCount: PurchaseSettings.shared.tipPromptDismissCount
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text(promptContent.headline)
                            .font(.brutalistHeading)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(promptContent.body)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
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
        .presentationDetents([.height(350)])
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

// MARK: - Tip Prompt Content

/// Context-aware messages for the tip prompt. Rotates based on user history
/// to keep the messaging fresh and relevant.
struct TipPromptContent {
    let headline: String
    let body: String

    /// Selects a random prompt based on whether the user has tipped before.
    /// Randomized so that repeat appearances don't feel scripted.
    static func select(tipCount: Int, dismissCount: Int) -> TipPromptContent {
        if tipCount > 0 {
            return returningTipperPrompts.randomElement()!
        }
        return firstTimePrompts.randomElement()!
    }

    // MARK: - First-Time Prompts

    /// Messages for users who haven't tipped yet. Each successive dismiss
    /// shows a different angle to find what resonates.
    private static let firstTimePrompts: [TipPromptContent] = [
        // First time: friendly, value-focused
        TipPromptContent(
            headline: "YOU'RE ON TOP OF IT",
            body: "Checkpoint is built by one developer.\nA small tip keeps it free and improving — plus unlocks an exclusive theme."
        ),
        // Second time: community angle
        TipPromptContent(
            headline: "KEEPING YOUR RIDE SHARP",
            body: "Tips from drivers like you fund every update.\nEach one also unlocks a rare theme for your dashboard."
        ),
        // Third time: short and direct
        TipPromptContent(
            headline: "LIKE CHECKPOINT?",
            body: "A quick tip goes a long way.\nEvery tip unlocks an exclusive theme."
        ),
        // Fourth+: minimal, low-pressure
        TipPromptContent(
            headline: "STILL HERE FOR YOU",
            body: "Checkpoint is free — tips help keep it that way.\nPlus, you'll unlock a rare theme."
        ),
    ]

    // MARK: - Returning Tipper Prompts

    /// Messages for users who have tipped before. Grateful tone,
    /// acknowledges their support, entices with more themes.
    private static let returningTipperPrompts: [TipPromptContent] = [
        TipPromptContent(
            headline: "THANKS FOR YOUR SUPPORT",
            body: "Your tips keep Checkpoint going.\nTip again to unlock another rare theme."
        ),
        TipPromptContent(
            headline: "YOU'RE A CHAMPION",
            body: "Every tip helps build the next feature.\nThere are more rare themes waiting for you."
        ),
    ]
}
