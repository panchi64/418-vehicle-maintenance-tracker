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

    @State private var isRevealed = false

    private var storeManager: StoreManager { StoreManager.shared }

    private var stats: TipPromptStats {
        TipPromptStats(
            servicesLogged: serviceLogs.count,
            servicesTracked: services.count,
            vehicleCount: vehicles.count,
            totalCost: serviceLogs.compactMap(\.cost).reduce(Decimal.zero, +),
            oldestLogDate: serviceLogs.map(\.performedDate).min(),
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

                    // Stats-driven header — mirrors ThemeRevealView pattern:
                    // small label on top, large stat headline, body below
                    VStack(spacing: Spacing.md) {
                        Text("SUPPORT CHECKPOINT")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .textCase(.uppercase)
                            .tracking(2)

                        Text(promptContent.headline)
                            .font(.brutalistTitle)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(promptContent.body)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .opacity(isRevealed ? 1 : 0)

                    Spacer()

                    // Tip buttons + dismiss — pinned to bottom
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

                        // Dismiss
                        Button {
                            handleDismiss()
                        } label: {
                            Text("Not now")
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.lg)
                    .opacity(isRevealed ? 1 : 0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        handleDismiss()
                    }
                    .toolbarButtonStyle()
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                isRevealed = true
            }
        }
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
        .buttonStyle(.instrument)
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
                            try? await Task.sleep(for: .seconds(0.5))
                            appState.unlockedTheme = theme
                        }
                    }
                } catch {
                    AnalyticsService.shared.capture(.purchaseFailed(product: product.id, error: error.localizedDescription))
                }
            }
        } label: {
            VStack(spacing: Spacing.xs) {
                Text(product.displayPrice)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                Text(product.displayName.replacingOccurrences(of: " Tip", with: ""))
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
        .buttonStyle(.instrument)
    }
}

// MARK: - Stats

/// Aggregated user stats used to personalize the tip prompt.
struct TipPromptStats {
    let servicesLogged: Int
    let servicesTracked: Int
    let vehicleCount: Int
    let totalCost: Decimal
    let oldestLogDate: Date?
    let hasTippedBefore: Bool

    var formattedCost: String? {
        guard totalCost > 0 else { return nil }
        return Formatters.currency.string(from: totalCost as NSDecimalNumber)
    }

    /// Months of maintenance history, nil if no logs
    var monthsOfHistory: Int? {
        guard let oldest = oldestLogDate else { return nil }
        let months = Calendar.current.dateComponents([.month], from: oldest, to: Date()).month ?? 0
        return months > 0 ? months : nil
    }
}

// MARK: - Tip Prompt Content

/// Builds personalized, stats-driven messages for the tip prompt.
///
/// Design: Collect all stat-based messages the user *qualifies* for, then
/// randomly pick one. This gives variety across appearances while keeping
/// every message grounded in real data. The "one developer" line stays
/// constant as the ask — only the stat framing rotates.
struct TipPromptContent {
    let headline: String
    let body: String

    static func select(from stats: TipPromptStats) -> TipPromptContent {
        if stats.hasTippedBefore {
            return pickRandom(from: returningTipperCandidates(stats: stats))
        }
        return pickRandom(from: firstTimeCandidates(stats: stats))
    }

    private static func pickRandom(from candidates: [TipPromptContent]) -> TipPromptContent {
        candidates.randomElement() ?? fallback
    }

    // MARK: - First-Time Candidates

    /// Builds every message the user's stats qualify for, then one is
    /// picked at random. More stats = bigger pool = more variety.
    private static func firstTimeCandidates(stats: TipPromptStats) -> [TipPromptContent] {
        var pool: [TipPromptContent] = []

        // Cost-based — strong signal, most concrete value
        if let cost = stats.formattedCost {
            pool.append(TipPromptContent(
                headline: "\(cost) IN MAINTENANCE TRACKED",
                body: "That's real money you're keeping an eye on.\nCheckpoint is made by one dev — a tip helps keep it free."
            ))
            pool.append(TipPromptContent(
                headline: "\(cost) LOGGED SO FAR",
                body: "You've got a clear picture of what your vehicle costs.\nThis app is a one-person project — tips help it stay free."
            ))
        }

        // Service log count — shows consistent engagement
        if stats.servicesLogged >= 10 {
            pool.append(TipPromptContent(
                headline: "\(stats.servicesLogged) SERVICES IN THE BOOKS",
                body: "That's a maintenance record any mechanic would respect.\nBuilt and maintained by one developer — tips make that possible."
            ))
        } else if stats.servicesLogged >= 3 {
            pool.append(TipPromptContent(
                headline: "\(stats.servicesLogged) SERVICES LOGGED",
                body: "You're building a solid maintenance history.\nCheckpoint is a one-person project — a tip helps keep it going."
            ))
        }

        // Tracked/scheduled services — forward-looking value
        if stats.servicesTracked >= 3 {
            pool.append(TipPromptContent(
                headline: "\(stats.servicesTracked) SERVICES ON YOUR RADAR",
                body: "Nothing's sneaking up on you.\nOne developer builds and maintains this — tips keep the updates coming."
            ))
        }

        // History depth — time-based engagement
        if let months = stats.monthsOfHistory, months >= 2 {
            pool.append(TipPromptContent(
                headline: "\(months) MONTHS OF HISTORY",
                body: "That's \(months) months of maintenance you'll never lose track of.\nCheckpoint is made by one dev — a tip helps keep it free."
            ))
        }

        // Multi-vehicle — power user
        if stats.vehicleCount > 1 {
            pool.append(TipPromptContent(
                headline: "\(stats.vehicleCount) VEHICLES, ONE PLACE",
                body: "Every vehicle's maintenance, organized.\nThis is a one-person project — tips help keep it free for everyone."
            ))
        }

        // Always include a general-purpose entry so the pool is never empty
        pool.append(fallback)

        return pool
    }

    // MARK: - Returning Tipper Candidates

    private static func returningTipperCandidates(stats: TipPromptStats) -> [TipPromptContent] {
        var pool: [TipPromptContent] = []

        if let cost = stats.formattedCost {
            pool.append(TipPromptContent(
                headline: "\(cost) AND COUNTING",
                body: "Your support helped get Checkpoint here.\nAnother tip means another rare theme for your collection."
            ))
        }

        if stats.servicesLogged >= 5 {
            pool.append(TipPromptContent(
                headline: "\(stats.servicesLogged) SERVICES AND GROWING",
                body: "Your history keeps getting stronger.\nTips fund the next feature — and unlock another rare theme."
            ))
        }

        if let months = stats.monthsOfHistory, months >= 3 {
            pool.append(TipPromptContent(
                headline: "\(months) MONTHS TOGETHER",
                body: "Thanks for sticking around — and for your past support.\nAnother tip unlocks another rare theme."
            ))
        }

        pool.append(TipPromptContent(
            headline: "STILL GOING STRONG",
            body: "Your past tips helped shape what Checkpoint is today.\nAnother one unlocks another rare theme."
        ))

        return pool
    }

    // MARK: - Fallback

    private static let fallback = TipPromptContent(
        headline: "YOUR MAINTENANCE, HANDLED",
        body: "Checkpoint is built and maintained by one developer.\nA tip helps keep it free — and unlocks a rare theme."
    )
}
