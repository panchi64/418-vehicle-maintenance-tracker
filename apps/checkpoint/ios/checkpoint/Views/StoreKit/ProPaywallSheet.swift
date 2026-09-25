//
//  ProPaywallSheet.swift
//  checkpoint
//
//  Brutalist paywall sheet for Checkpoint Pro upgrade
//

import SwiftUI
import StoreKit

struct ProPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var storeManager: StoreManager { StoreManager.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        VStack(spacing: Spacing.sm) {
                            Text(L10n.storeProTitle)
                                .font(.brutalistTitle)
                                .foregroundStyle(Theme.accent)

                            // Price display
                            if let product = storeManager.proProduct() {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: Spacing.sm) { priceLine(product) }
                                    VStack(spacing: Spacing.xs) { priceLine(product) }
                                }
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.screenHorizontal)
                            }
                        }
                        .padding(.top, Spacing.lg)

                        // Feature list
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            InstrumentSectionHeader(title: L10n.storeProWhatYouGet)

                            featureRow(icon: "car.2.fill", text: L10n.storeProFeatureVehicles)
                            featureRow(icon: "paintpalette.fill", text: L10n.storeProFeatureThemes)
                            featureRow(icon: "cpu", text: L10n.storeProFeatureAI)
                            featureRow(icon: "chart.bar.fill", text: L10n.storeProFeatureInsights)
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)

                        // Purchase button
                        VStack(spacing: Spacing.md) {
                            Button {
                                Task {
                                    AnalyticsService.shared.capture(.purchaseAttempted(product: "pro.unlock"))
                                    #if DEBUG
                                    await storeManager.simulatePurchase(.proUnlock)
                                    AnalyticsService.shared.capture(.purchaseSucceeded(product: "pro.unlock"))
                                    dismiss()
                                    #else
                                    do {
                                        let transaction = try await storeManager.purchase(.proUnlock)
                                        if transaction != nil {
                                            AnalyticsService.shared.capture(.purchaseSucceeded(product: "pro.unlock"))
                                            dismiss()
                                        }
                                    } catch {
                                        AnalyticsService.shared.capture(.purchaseFailed(product: "pro.unlock", error: error.localizedDescription))
                                    }
                                    #endif
                                }
                            } label: {
                                if storeManager.purchaseInProgress {
                                    ProgressView()
                                        .tint(Theme.surfaceInstrument)
                                } else {
                                    Text(L10n.storeProUnlock)
                                }
                            }
                            .buttonStyle(.primary)
                            .disabled(storeManager.purchaseInProgress)
                            .padding(.horizontal, Spacing.screenHorizontal)

                            // Error display
                            if let error = storeManager.purchaseError {
                                Text(error)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.statusOverdue)
                                    .padding(.horizontal, Spacing.screenHorizontal)
                            }

                            // Restore button
                            Button {
                                Task { await RestorePurchasesAction.run() }
                            } label: {
                                Text(L10n.settingsRestorePurchases)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textTertiary)
                                    .minimumTouchTarget()
                            }
                        }
                        .padding(.top, Spacing.md)
                    }
                }
            }
            .navigationTitle(L10n.storeProNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                        .toolbarButtonStyle()
                }
            }
            .onAppear {
                AnalyticsService.shared.capture(.paywallShown(trigger: "vehicle_limit"))
            }
        }
        .presentationDetents([.medium, .large])
    }

    // Hardcoded "original" price for strikethrough marketing display;
    // StoreKit does not expose a pre-discount price for introductory offers
    @ViewBuilder
    private func priceLine(_ product: Product) -> some View {
        Text(verbatim: "$14.99")
            .font(.brutalistBody)
            .foregroundStyle(Theme.textTertiary)
            .strikethrough()

        Text(L10n.storeProLaunchPrice(product.displayPrice))
            .font(.brutalistHeading)
            .foregroundStyle(Theme.textPrimary)
    }

    private func featureRow(icon: String, text: String) -> some View {
        Label {
            Text(text)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
    }
}
