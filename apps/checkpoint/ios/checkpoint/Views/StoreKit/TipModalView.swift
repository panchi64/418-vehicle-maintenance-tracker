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

    /// True when the app asked (the post-action prompt); false when the user
    /// opened the tip jar from Settings. Only an app-initiated prompt that is
    /// closed without a tip grows the backoff.
    var isPrompt = false

    @State private var isRevealed = false
    @State private var didTip = false
    @State private var purchaseErrorMessage: String?

    private var storeManager: StoreManager { StoreManager.shared }

    private var stats: TipPromptStats {
        // Use visit-aware totals: visits count once, standalone logs count once.
        let totalCost = serviceLogs.honestTotalCost()
        let eventCount = serviceLogs.distinctVisitCount()
        let oldestLog = serviceLogs.map(\.performedDate).min()
        let selectedVehicle = appState.selectedVehicle

        // Average cost per money event (visit or standalone log).
        let averageCost: Decimal? = eventCount >= 2
            ? totalCost / Decimal(eventCount)
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

    /// Picked once per presentation. Selection is random, so re-deriving it
    /// on every body pass (the reveal animation alone triggers one) could
    /// swap the message mid-read — or pair one candidate's headline with
    /// another's body.
    @State private var chosenContent: TipPromptContent?

    var body: some View {
        let promptContent = chosenContent ?? TipPromptContent.select(from: stats)
        return NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    // Stats-driven header — mirrors ThemeRevealView pattern:
                    // small label on top, large stat headline, body below
                    VStack(spacing: Spacing.md) {
                        Text(L10n.tipSupportCheckpoint)
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .textCase(.uppercase)
                            .tracking(2)
                            .accessibilityAddTraits(.isHeader)

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

                    // Tip buttons + collection progress
                    TipTierList { productID in
                        await handleTipPurchase(productID)
                    }

                    if let purchaseErrorMessage {
                        FormAdvisory.caution(purchaseErrorMessage) {
                            self.purchaseErrorMessage = nil
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }

                    // Dismiss
                    Button {
                        dismiss()
                    } label: {
                        Text(L10n.tipNotNow)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .minimumTouchTarget()
                    }

                    Spacer()
                }
                .scrollingWhenTooTall()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose) {
                        dismiss()
                    }
                    .toolbarButtonStyle()
                }
            }
        }
        .presentationDetents([.fraction(0.65), .large])
        .onAppear {
            if chosenContent == nil {
                chosenContent = promptContent
            }
            withAnimation(.easeOut(duration: 0.4)) {
                isRevealed = true
            }
        }
        // Every way out — Not now, Close, or a swipe down — lands here, so a
        // swipe counts as the dismissal it is. It used to skip the backoff
        // entirely, so a user who swiped was re-prompted at the base rate.
        .onDisappear(perform: recordCloseWithoutTip)
    }

    // MARK: - Actions

    private func recordCloseWithoutTip() {
        guard !didTip else { return }
        let settings = PurchaseSettings.shared
        AnalyticsService.shared.capture(.tipModalDismissed(dismissCount: settings.tipPromptDismissCount + (isPrompt ? 1 : 0)))
        if isPrompt {
            settings.recordTipPromptDismiss()
        }
    }

    private func handleTipPurchase(_ productID: StoreManager.ProductID) async {
        purchaseErrorMessage = nil

        #if DEBUG
        if storeManager.tipProducts().isEmpty {
            await storeManager.simulatePurchase(productID)
            didTip = true
            PurchaseSettings.shared.recordTip()
            dismiss()
            if let theme = ThemeManager.shared.unlockRandomRareTheme() {
                AnalyticsService.shared.capture(.themeUnlocked(themeID: theme.id, tier: "rare"))
                try? await Task.sleep(for: .seconds(0.5))
                appState.unlockedTheme = theme
            }
            return
        }
        #endif

        AnalyticsService.shared.capture(.purchaseAttempted(product: productID.rawValue))
        do {
            let transaction = try await storeManager.purchase(productID)
            if transaction != nil {
                AnalyticsService.shared.capture(.purchaseSucceeded(product: productID.rawValue))
                didTip = true
                PurchaseSettings.shared.recordTip()
                dismiss()
                if let theme = ThemeManager.shared.unlockRandomRareTheme() {
                    AnalyticsService.shared.capture(.themeUnlocked(themeID: theme.id, tier: "rare"))
                    try? await Task.sleep(for: .seconds(0.5))
                    appState.unlockedTheme = theme
                }
            } else if let storeError = storeManager.purchaseError {
                // No transaction and no throw: the store could not offer the
                // product (it sets its own message). A user cancel or a
                // pending approval leaves `purchaseError` nil and says nothing.
                purchaseErrorMessage = storeError
            }
        } catch {
            AnalyticsService.shared.capture(.purchaseFailed(product: productID.rawValue, error: error.localizedDescription))
            // The failure used to be swallowed: the sheet sat there as if the
            // tap had done nothing. Say that nothing was charged and what to do.
            purchaseErrorMessage = L10n.tipPurchaseFailed
        }
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
