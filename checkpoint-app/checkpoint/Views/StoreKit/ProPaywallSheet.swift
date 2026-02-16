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
                            Text("CHECKPOINT PRO")
                                .font(.brutalistTitle)
                                .foregroundStyle(Theme.accent)

                            // Price display
                            if let product = storeManager.proProduct() {
                                HStack(spacing: Spacing.sm) {
                                    // TODO: Replace hardcoded price with StoreKit original price when available
                                    Text("$14.99")
                                        .font(.brutalistBody)
                                        .foregroundStyle(Theme.textTertiary)
                                        .strikethrough()

                                    Text("\(product.displayPrice) LAUNCH PRICE")
                                        .font(.brutalistHeading)
                                        .foregroundStyle(Theme.textPrimary)
                                }
                            }
                        }
                        .padding(.top, Spacing.lg)

                        // Feature list
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            InstrumentSectionHeader(title: "What You Get")

                            featureRow(icon: "car.2.fill", text: "Unlimited vehicles")
                            featureRow(icon: "paintpalette.fill", text: "Full theme collection")
                            featureRow(icon: "cpu", text: "Future AI features")
                            featureRow(icon: "chart.bar.fill", text: "Future advanced insights")
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
                                    Text("UNLOCK PRO")
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
                                Task { await storeManager.restorePurchases() }
                            } label: {
                                Text("Restore Purchases")
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .padding(.top, Spacing.md)
                    }
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
            }
            .onAppear {
                AnalyticsService.shared.capture(.paywallShown(trigger: "vehicle_limit"))
            }
        }
        .presentationDetents([.medium])
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)

            Text(text)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
