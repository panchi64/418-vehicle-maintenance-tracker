//
//  TipTierList.swift
//  checkpoint
//
//  Renders the tip tier selection buttons, theme unlock hint,
//  and collection progress. Extracted from TipModalView.
//

import SwiftUI
import StoreKit

struct TipTierList: View {
    var onPurchase: (StoreManager.ProductID) async -> Void

    private var storeManager: StoreManager { StoreManager.shared }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Tip tier buttons in instrument card containers
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

            // Theme unlock hint
            Text("EVERY TIP UNLOCKS A RARE THEME")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1.5)
        }
        .padding(.horizontal, Spacing.screenHorizontal)

        // Collection progress
        let rareThemes = ThemeManager.shared.allThemes.filter { $0.tier == .rare }
        let ownedRare = rareThemes.filter { ThemeManager.shared.isOwned($0) }
        if rareThemes.count > 0 && ownedRare.count < rareThemes.count {
            Text("\(ownedRare.count)/\(rareThemes.count) RARE THEMES COLLECTED")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
        }
    }

    // MARK: - Debug Buttons

    #if DEBUG
    private func debugTipButton(label: String, price: String, productID: StoreManager.ProductID) -> some View {
        Button {
            Task {
                await onPurchase(productID)
            }
        } label: {
            tipButtonLabel(price: price, label: label)
        }
        .buttonStyle(.instrument)
    }

    private var debugTipSmall: some View {
        debugTipButton(label: "Snack", price: "$1.99", productID: .tipSmall)
    }

    private var debugTipMedium: some View {
        debugTipButton(label: "Coffee Run", price: "$4.99", productID: .tipMedium)
    }

    private var debugTipLarge: some View {
        debugTipButton(label: "Lunch", price: "$9.99", productID: .tipLarge)
    }
    #endif

    // MARK: - Tip Button

    private static let tipLabels: [String: String] = [
        "tip.small": "Snack",
        "tip.medium": "Coffee Run",
        "tip.large": "Lunch",
    ]

    private func tipLabel(for product: Product) -> String {
        Self.tipLabels[product.id] ?? product.displayName.replacingOccurrences(of: " Tip", with: "")
    }

    private func tipButton(for product: Product) -> some View {
        Button {
            Task {
                guard let productID = StoreManager.ProductID(rawValue: product.id) else { return }
                await onPurchase(productID)
            }
        } label: {
            tipButtonLabel(price: product.displayPrice, label: tipLabel(for: product))
        }
        .buttonStyle(.instrument)
    }

    // MARK: - Shared Label

    private func tipButtonLabel(price: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(price)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
        )
    }
}
