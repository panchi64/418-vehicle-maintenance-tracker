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
        let costs = serviceLogs.compactMap(\.cost)
        let totalCost = costs.reduce(Decimal.zero, +)
        let oldestLog = serviceLogs.map(\.performedDate).min()
        let selectedVehicle = appState.selectedVehicle

        // Compute average cost per service
        let averageCost: Decimal? = costs.count >= 2
            ? totalCost / Decimal(costs.count)
            : nil

        // Monthly spend: total cost / months of history
        let monthsOfHistory: Int? = {
            guard let oldest = oldestLog else { return nil }
            let m = Calendar.current.dateComponents([.month], from: oldest, to: Date()).month ?? 0
            return m > 0 ? m : nil
        }()
        let monthlySpend: Decimal? = {
            guard let months = monthsOfHistory, months >= 2, totalCost > 0 else { return nil }
            return totalCost / Decimal(months)
        }()

        // Count services that are due soon or overdue on the selected vehicle
        let dueSoonOrOverdueCount: Int = {
            guard let vehicle = selectedVehicle else { return 0 }
            let mileage = vehicle.effectiveMileage
            return services.filter { service in
                guard service.vehicle?.id == vehicle.id else { return false }
                let s = service.status(currentMileage: mileage)
                return s == .dueSoon || s == .overdue
            }.count
        }()

        // Next upcoming service name on selected vehicle
        let nextServiceName: String? = {
            guard let vehicle = selectedVehicle else { return nil }
            let mileage = vehicle.effectiveMileage
            let pace = vehicle.dailyMilesPace
            return services
                .filter { $0.vehicle?.id == vehicle.id && $0.hasDueTracking }
                .sorted { $0.urgencyScore(currentMileage: mileage, dailyPace: pace) < $1.urgencyScore(currentMileage: mileage, dailyPace: pace) }
                .first?.name
        }()

        return TipPromptStats(
            servicesLogged: serviceLogs.count,
            servicesTracked: services.filter(\.hasDueTracking).count,
            vehicleCount: vehicles.count,
            totalCost: totalCost,
            averageCost: averageCost,
            monthlySpend: monthlySpend,
            monthsOfHistory: monthsOfHistory,
            dueSoonOrOverdueCount: dueSoonOrOverdueCount,
            nextServiceName: nextServiceName,
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

/// Aggregated insights computed from the user's actual data.
/// Each field represents something genuinely useful to surface.
struct TipPromptStats {
    let servicesLogged: Int
    let servicesTracked: Int
    let vehicleCount: Int
    let totalCost: Decimal
    let averageCost: Decimal?
    let monthlySpend: Decimal?
    let monthsOfHistory: Int?
    let dueSoonOrOverdueCount: Int
    let nextServiceName: String?
    let hasTippedBefore: Bool

    var formattedTotalCost: String? {
        guard totalCost > 0 else { return nil }
        return Formatters.currency.string(from: totalCost as NSDecimalNumber)
    }

    var formattedAverageCost: String? {
        guard let avg = averageCost else { return nil }
        return Formatters.currency.string(from: avg as NSDecimalNumber)
    }

    var formattedMonthlySpend: String? {
        guard let monthly = monthlySpend else { return nil }
        return Formatters.currency.string(from: monthly as NSDecimalNumber)
    }
}

// MARK: - Tip Prompt Content

/// Builds personalized messages grounded in genuinely useful insights.
///
/// Design: Each message teaches the user something about their vehicle
/// or spending they might not have thought about — the kind of thing
/// a friend who's good with cars would point out. The ask at the end
/// is human and grateful, never transactional.
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

    // The closing line every first-time message ends with.
    // Genuine, not salesy — acknowledges the exchange.
    private static let closingLine = "I built Checkpoint to make car ownership easier. If it's helped you, a tip would mean a lot."

    // MARK: - First-Time Candidates

    private static func firstTimeCandidates(stats: TipPromptStats) -> [TipPromptContent] {
        var pool: [TipPromptContent] = []

        // Monthly spend — genuinely useful for budgeting
        if let monthly = stats.formattedMonthlySpend {
            pool.append(TipPromptContent(
                headline: "\(monthly)/MONTH",
                body: "That's your average maintenance spend based on your history. Useful for budgeting — most people have no idea what their car actually costs them.\n\n\(closingLine)"
            ))
        }

        // Average cost per service — helps spot overcharges
        if let avg = stats.formattedAverageCost, stats.servicesLogged >= 3 {
            pool.append(TipPromptContent(
                headline: "\(avg) AVG PER SERVICE",
                body: "Across your \(stats.servicesLogged) logged services, that's your average. Having this number makes it easier to notice when a bill seems off.\n\n\(closingLine)"
            ))
        }

        // Upcoming due services — actionable awareness
        if stats.dueSoonOrOverdueCount > 0, let next = stats.nextServiceName {
            let serviceWord = stats.dueSoonOrOverdueCount == 1 ? "service" : "services"
            pool.append(TipPromptContent(
                headline: "\(stats.dueSoonOrOverdueCount) \(serviceWord.uppercased()) NEED ATTENTION",
                body: "Your \(next) is next up. Checkpoint tracks deadlines by both date and mileage so nothing slips through — whichever comes first.\n\n\(closingLine)"
            ))
        }

        // Service tracking count — explain what it's doing for them
        if stats.servicesTracked >= 3 {
            pool.append(TipPromptContent(
                headline: "\(stats.servicesTracked) SERVICES MONITORED",
                body: "Checkpoint is watching \(stats.servicesTracked) services for you right now — tracking due dates and mileage thresholds so you don't have to remember.\n\n\(closingLine)"
            ))
        }

        // Deep history — explain the resale/warranty value
        if let months = stats.monthsOfHistory, months >= 3, stats.servicesLogged >= 5 {
            pool.append(TipPromptContent(
                headline: "\(months) MONTHS OF RECORDS",
                body: "That's \(stats.servicesLogged) services across \(months) months. A complete maintenance history like this adds real value if you ever sell or need warranty work.\n\n\(closingLine)"
            ))
        }

        // Total cost tracked — frame as visibility into ownership cost
        if let total = stats.formattedTotalCost, stats.servicesLogged >= 3 {
            pool.append(TipPromptContent(
                headline: "\(total) TOTAL LOGGED",
                body: "That's every dollar you've put into maintenance, in one place. Most people lose track of this — you haven't.\n\n\(closingLine)"
            ))
        }

        // Multi-vehicle — explain the organizational value
        if stats.vehicleCount > 1 {
            pool.append(TipPromptContent(
                headline: "\(stats.vehicleCount) VEHICLES TRACKED",
                body: "Each vehicle has its own schedules, mileage, and history. Checkpoint keeps them separate so you always know which car needs what, and when.\n\n\(closingLine)"
            ))
        }

        pool.append(fallback)
        return pool
    }

    // MARK: - Returning Tipper Candidates

    private static func returningTipperCandidates(stats: TipPromptStats) -> [TipPromptContent] {
        var pool: [TipPromptContent] = []

        if let monthly = stats.formattedMonthlySpend {
            pool.append(TipPromptContent(
                headline: "\(monthly)/MONTH",
                body: "Your average maintenance spend — tracked because you took the time to log it. Your past support helped make this possible, and another tip unlocks a rare theme."
            ))
        }

        if stats.dueSoonOrOverdueCount > 0, let next = stats.nextServiceName {
            pool.append(TipPromptContent(
                headline: "\(next.uppercased()) IS COMING UP",
                body: "Checkpoint's keeping an eye on it. Your tips help keep these features free for everyone — and each one unlocks a rare theme."
            ))
        }

        if let months = stats.monthsOfHistory, months >= 3 {
            pool.append(TipPromptContent(
                headline: "\(months) MONTHS OF HISTORY",
                body: "That's a solid record that's only getting more valuable. Thanks for your past support — another tip unlocks another rare theme."
            ))
        }

        pool.append(TipPromptContent(
            headline: "THANKS FOR BEING HERE",
            body: "Your past tips helped shape what Checkpoint is today. If you'd like to keep supporting it, another tip unlocks a rare theme."
        ))

        return pool
    }

    // MARK: - Fallback

    private static let fallback = TipPromptContent(
        headline: "YOUR MAINTENANCE, ORGANIZED",
        body: "Checkpoint tracks your services, costs, and deadlines so you don't have to keep it all in your head.\n\n\(closingLine)"
    )
}
