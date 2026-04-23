//
//  StoreManager.swift
//  checkpoint
//
//  StoreKit 2 purchase engine for Pro unlock and tips
//

import StoreKit
import os

private let storeLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "StoreManager")

@Observable
@MainActor
final class StoreManager {
    static let shared = StoreManager()

    enum ProductID: String, CaseIterable {
        case proUnlock = "pro.unlock"
        case tipSmall = "tip.small"
        case tipMedium = "tip.medium"
        case tipLarge = "tip.large"

        var isConsumable: Bool {
            switch self {
            case .proUnlock: return false
            case .tipSmall, .tipMedium, .tipLarge: return true
            }
        }
    }

    // MARK: - Properties

    private(set) var products: [Product] = []
    #if DEBUG
    var isPro: Bool = true
    #else
    var isPro: Bool = false
    #endif
    var purchaseInProgress: Bool = false
    var purchaseError: String?

    private var transactionListener: Task<Void, Error>?

    // MARK: - Init

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await checkEntitlements()
        }
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            let ids = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
            storeLogger.info("Loaded \(self.products.count) products")
        } catch {
            storeLogger.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    func proProduct() -> Product? {
        products.first(where: { $0.id == ProductID.proUnlock.rawValue })
    }

    func tipProducts() -> [Product] {
        products.filter { product in
            [ProductID.tipSmall.rawValue, ProductID.tipMedium.rawValue, ProductID.tipLarge.rawValue]
                .contains(product.id)
        }
        .sorted { $0.price < $1.price }
    }

    // MARK: - Purchase

    #if DEBUG
    /// Simulates a successful purchase in debug builds without StoreKit
    func simulatePurchase(_ productID: ProductID) async {
        storeLogger.info("DEBUG: Simulating purchase for \(productID.rawValue)")
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        try? await Task.sleep(for: .seconds(0.3))
        if productID == .proUnlock {
            isPro = true
            PurchaseSettings.shared.isPro = true
        }
    }
    #endif

    func purchase(_ productID: ProductID) async throws -> StoreKit.Transaction? {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            storeLogger.error("Product not found: \(productID.rawValue)")
            return nil
        }

        purchaseInProgress = true
        purchaseError = nil

        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkEntitlements()
                storeLogger.info("Purchase succeeded: \(productID.rawValue)")
                return transaction

            case .userCancelled:
                storeLogger.info("Purchase cancelled by user: \(productID.rawValue)")
                return nil

            case .pending:
                storeLogger.info("Purchase pending: \(productID.rawValue)")
                return nil

            @unknown default:
                storeLogger.warning("Unknown purchase result for: \(productID.rawValue)")
                return nil
            }
        } catch {
            purchaseError = error.localizedDescription
            storeLogger.error("Purchase failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Entitlements

    func checkEntitlements() async {
        #if DEBUG
        isPro = true
        PurchaseSettings.shared.isPro = true
        #else
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == ProductID.proUnlock.rawValue {
                    hasPro = true
                }
            }
        }

        isPro = hasPro
        PurchaseSettings.shared.isPro = hasPro
        #endif
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
            storeLogger.info("Purchases restored")
        } catch {
            storeLogger.error("Restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.checkEntitlements()
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
