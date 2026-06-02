import StoreKit

@Observable
final class StoreKitManager {
    nonisolated static let lifetimeProductID = "com.john.armyapp.Greekdrivingtest.lifetime_unlock"
    nonisolated static let yearlyProductID = "com.john.armyapp.Greekdrivingtest.yearly"

    // MARK: - State
    private(set) var lifetimeProduct: Product?
    private(set) var yearlyProduct: Product?
    private(set) var isLifetimePurchased = false
    private(set) var isSubscriptionActive = false
    private(set) var isLoading = false
    private(set) var purchaseError: String?
    private(set) var isTrialActive = false
    private(set) var subscriptionExpiryDate: Date?
    private(set) var productsLoaded = false

    var isUnlocked: Bool { isLifetimePurchased || isSubscriptionActive }

    var lifetimeDisplayPrice: String { lifetimeProduct?.displayPrice ?? "€9.99" }
    var yearlyDisplayPrice: String { yearlyProduct?.displayPrice ?? "€1.99" }

    var trialDaysRemaining: Int {
        guard isTrialActive, let expiry = subscriptionExpiryDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0)
    }

    @ObservationIgnored
    private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    init() {
        transactionListener = Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let tx) = result {
                    await self.handleTransaction(tx)
                    await tx.finish()
                }
            }
        }

        Task { [weak self] in
            await self?.loadProducts()
            await self?.updatePurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Products

    @MainActor
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.lifetimeProductID, Self.yearlyProductID])
            for product in products {
                if product.id == Self.lifetimeProductID {
                    lifetimeProduct = product
                } else if product.id == Self.yearlyProductID {
                    yearlyProduct = product
                }
            }
            productsLoaded = true
            purchaseError = nil
        } catch {
            purchaseError = "Failed to load products. Check your internet connection."
            productsLoaded = false
        }
    }

    // MARK: - Entitlements

    @MainActor
    func updatePurchaseStatus() async {
        isLifetimePurchased = false
        isSubscriptionActive = false
        isTrialActive = false
        subscriptionExpiryDate = nil

        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result {
                handleTransaction(tx)
            }
        }
    }

    @MainActor
    private func handleTransaction(_ transaction: Transaction) {
        if transaction.productID == Self.lifetimeProductID {
            isLifetimePurchased = true
            return
        }

        guard transaction.productID == Self.yearlyProductID,
              let expirationDate = transaction.expirationDate,
              expirationDate > Date()
        else { return }

        isSubscriptionActive = true
        subscriptionExpiryDate = expirationDate

        if transaction.offerType == .introductory {
            isTrialActive = true
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ productID: String) async {
        let product: Product?
        if productID == Self.lifetimeProductID {
            product = lifetimeProduct
        } else {
            product = yearlyProduct
        }

        guard let product else {
            purchaseError = "Product unavailable. Retrying..."
            await loadProducts()
            return
        }

        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    handleTransaction(tx)
                    await tx.finish()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    @MainActor
    func retryLoadProducts() async {
        purchaseError = nil
        await loadProducts()
    }

    // MARK: - Restore

    @MainActor
    func restorePurchases() async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
