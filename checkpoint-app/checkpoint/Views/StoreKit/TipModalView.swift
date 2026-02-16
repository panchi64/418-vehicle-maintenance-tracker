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
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, Spacing.lg)

                        if let closing = promptContent.closing {
                            Text(closing)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, Spacing.lg)
                        }
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
        .presentationDetents([.fraction(0.65)])
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
        debugTipButton(label: "Snack", price: "$1.99", productID: .tipSmall)
    }

    private var debugTipMedium: some View {
        debugTipButton(label: "Coffee Run", price: "$4.99", productID: .tipMedium)
    }

    private var debugTipLarge: some View {
        debugTipButton(label: "Lunch", price: "$9.99", productID: .tipLarge)
    }
    #endif

    private static let tipLabels: [String: String] = [
        "tip.small": "Snack",
        "tip.medium": "Coffee Run",
        "tip.large": "Lunch",
    ]

    private func tipLabel(for product: Product) -> String {
        Self.tipLabels[product.id] ?? product.displayName.replacingOccurrences(of: " Tip", with: "")
    }

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
                Text(tipLabel(for: product))
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
    let closing: String?

    static func select(from stats: TipPromptStats) -> TipPromptContent {
        if stats.hasTippedBefore {
            return pickRandom(from: returningTipperCandidates(stats: stats))
        }
        return pickRandom(from: firstTimeCandidates(stats: stats))
    }

    private static func pickRandom(from candidates: [TipPromptContent]) -> TipPromptContent {
        candidates.randomElement() ?? fallback
    }

    // Short closing shown as tertiary caption below the body.
    private static let closingLine = "Checkpoint looks after your car — tips are a great way to return the favor."

    // MARK: - First-Time Candidates

    private static func firstTimeCandidates(stats: TipPromptStats) -> [TipPromptContent] {
        var pool: [TipPromptContent] = []

        // Monthly spend
        if let monthly = stats.formattedMonthlySpend {
            pool.append(TipPromptContent(
                headline: "\(monthly)/MONTH",
                body: "Your average maintenance spend. Most people have no idea what their car actually costs them.",
                closing: closingLine
            ))
        }

        // Average cost per service
        if let avg = stats.formattedAverageCost, stats.servicesLogged >= 3 {
            pool.append(TipPromptContent(
                headline: "\(avg) AVG PER SERVICE",
                body: "Across \(stats.servicesLogged) logged services. Handy for spotting when a bill seems off.",
                closing: closingLine
            ))
        }

        // Upcoming due services
        if stats.dueSoonOrOverdueCount > 0, let next = stats.nextServiceName {
            let serviceWord = stats.dueSoonOrOverdueCount == 1 ? "service" : "services"
            pool.append(TipPromptContent(
                headline: "\(stats.dueSoonOrOverdueCount) \(serviceWord.uppercased()) NEED ATTENTION",
                body: "\(next) is next up. Tracked by both date and mileage — whichever comes first.",
                closing: closingLine
            ))
        }

        // Service tracking count
        if stats.servicesTracked >= 3 {
            pool.append(TipPromptContent(
                headline: "\(stats.servicesTracked) SERVICES MONITORED",
                body: "Due dates and mileage thresholds tracked for you, so you don't have to remember.",
                closing: closingLine
            ))
        }

        // Deep history
        if let months = stats.monthsOfHistory, months >= 3, stats.servicesLogged >= 5 {
            pool.append(TipPromptContent(
                headline: "\(months) MONTHS OF RECORDS",
                body: "\(stats.servicesLogged) services logged. A history like this adds real value at resale or for warranty work.",
                closing: closingLine
            ))
        }

        // Total cost tracked
        if let total = stats.formattedTotalCost, stats.servicesLogged >= 3 {
            pool.append(TipPromptContent(
                headline: "\(total) TOTAL LOGGED",
                body: "Every dollar you've put into maintenance, in one place. Most people lose track — you haven't.",
                closing: closingLine
            ))
        }

        // Multi-vehicle
        if stats.vehicleCount > 1 {
            pool.append(TipPromptContent(
                headline: "\(stats.vehicleCount) VEHICLES TRACKED",
                body: "Separate schedules, mileage, and history for each. Always know which car needs what.",
                closing: closingLine
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
                body: "Your average spend — tracked because you took the time to log it.",
                closing: "Another tip unlocks a rare theme."
            ))
        }

        if stats.dueSoonOrOverdueCount > 0, let next = stats.nextServiceName {
            pool.append(TipPromptContent(
                headline: "\(next.uppercased()) IS COMING UP",
                body: "Checkpoint's keeping an eye on it for you.",
                closing: "Another tip unlocks a rare theme."
            ))
        }

        if let months = stats.monthsOfHistory, months >= 3 {
            pool.append(TipPromptContent(
                headline: "\(months) MONTHS OF HISTORY",
                body: "A solid record that's only getting more valuable.",
                closing: "Another tip unlocks a rare theme."
            ))
        }

        pool.append(TipPromptContent(
            headline: "THANKS FOR BEING HERE",
            body: "Your past tips helped shape what Checkpoint is today.",
            closing: "Another tip unlocks a rare theme."
        ))

        return pool
    }

    // MARK: - Fallback

    private static let fallback = TipPromptContent(
        headline: "YOUR MAINTENANCE, ORGANIZED",
        body: "Services, costs, and deadlines — so you don't have to keep it all in your head.",
        closing: closingLine
    )
}
