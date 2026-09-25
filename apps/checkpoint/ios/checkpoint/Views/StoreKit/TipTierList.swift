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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var storeManager: StoreManager { StoreManager.shared }

    /// Three tiers side by side don't fit at accessibility text sizes; they
    /// stack instead.
    private var tierLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.sm))
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            tierLayout {
                #if DEBUG
                if storeManager.tipProducts().isEmpty {
                    ForEach(TipTier.debugOptions, id: \.productID) { option in
                        tierButton(productID: option.productID, price: option.price, label: option.label)
                    }
                } else {
                    productButtons
                }
                #else
                productButtons
                #endif
            }

            Text(L10n.tipEveryTipUnlocks)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1.5)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.screenHorizontal)

        let progress = RareThemeProgress.current
        if progress.total > 0 && !progress.isComplete {
            Text(progress.text)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1)
                .multilineTextAlignment(.center)
        }
    }

    private var productButtons: some View {
        ForEach(storeManager.tipProducts(), id: \.id) { product in
            if let productID = StoreManager.ProductID(rawValue: product.id) {
                tierButton(
                    productID: productID,
                    price: product.displayPrice,
                    label: TipTier.label(for: product)
                )
            }
        }
    }

    private func tierButton(productID: StoreManager.ProductID, price: String, label: String) -> some View {
        Button {
            Task { await onPurchase(productID) }
        } label: {
            VStack(spacing: Spacing.xs) {
                Text(price)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                Text(label)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum)
            .padding(.vertical, Spacing.sm)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.instrument)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Tier naming

/// The friendly names for the tip products, shared by the tip prompt and the
/// Settings tip jar so the two can't label the same product differently.
enum TipTier {
    static func label(for productID: StoreManager.ProductID) -> String? {
        switch productID {
        case .tipSmall: return L10n.tipTierSmall
        case .tipMedium: return L10n.tipTierMedium
        case .tipLarge: return L10n.tipTierLarge
        case .proUnlock: return nil
        }
    }

    static func label(for product: Product) -> String {
        StoreManager.ProductID(rawValue: product.id).flatMap(label(for:))
            ?? product.displayName
    }

    #if DEBUG
    struct DebugOption {
        let productID: StoreManager.ProductID
        let price: String
        var label: String { TipTier.label(for: productID) ?? "" }
    }

    /// Stand-ins shown when StoreKit returns no products (simulator without a
    /// StoreKit configuration).
    static let debugOptions: [DebugOption] = [
        DebugOption(productID: .tipSmall, price: "$1.99"),
        DebugOption(productID: .tipMedium, price: "$4.99"),
        DebugOption(productID: .tipLarge, price: "$9.99"),
    ]
    #endif
}

// MARK: - Rare theme progress

struct RareThemeProgress {
    let owned: Int
    let total: Int

    var isComplete: Bool { owned >= total }

    var text: String {
        isComplete ? L10n.tipAllRareCollected : L10n.tipRareProgress(owned: owned, total: total)
    }

    @MainActor static var current: RareThemeProgress {
        let manager = ThemeManager.shared
        let rare = manager.allThemes.filter { $0.tier == .rare }
        return RareThemeProgress(
            owned: rare.filter { manager.isOwned($0) }.count,
            total: rare.count
        )
    }
}
