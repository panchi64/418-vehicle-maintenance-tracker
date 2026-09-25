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
                // Queued by the router until this sheet has closed.
                appState.present(.themeReveal(theme))
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
                    // Queued by the router until this sheet has closed.
                    appState.present(.themeReveal(theme))
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
