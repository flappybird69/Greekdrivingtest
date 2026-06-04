import StoreKit

@Observable
final class StoreKitManager {
    nonisolated static let monthlyProductID = "com.john.armyapp.Greekdrivingtest.monthly"
    nonisolated static let onceProductID = "com.john.armyapp.Greekdrivingtest.once"

    private(set) var monthlyProduct: Product?
    private(set) var onceProduct: Product?
    private(set) var isMonthlySubscriptionActive = false
    private(set) var isOncePurchased = false
    private(set) var isLoading = false
    private(set) var purchaseError: String?
    private(set) var isTrialActive = false
    private(set) var subscriptionExpiryDate: Date?
    private(set) var productsLoaded = false

    var isUnlocked: Bool { isMonthlySubscriptionActive || isOncePurchased }

    var monthlyDisplayPrice: String { monthlyProduct?.displayPrice ?? "€0.99" }
    var onceDisplayPrice: String { onceProduct?.displayPrice ?? "€4.99" }

    var trialDaysRemaining: Int {
        guard isTrialActive, let expiry = subscriptionExpiryDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0)
    }

    @ObservationIgnored
    private var transactionListener: Task<Void, Never>?

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

    @MainActor
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.monthlyProductID, Self.onceProductID])
            for product in products {
                if product.id == Self.monthlyProductID {
                    monthlyProduct = product
                } else if product.id == Self.onceProductID {
                    onceProduct = product
                }
            }
            productsLoaded = true
            purchaseError = nil
        } catch {
            purchaseError = "Failed to load products. Check your internet connection."
            productsLoaded = false
        }
    }

    @MainActor
    func updatePurchaseStatus() async {
        isMonthlySubscriptionActive = false
        isOncePurchased = false
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
        if transaction.productID == Self.onceProductID {
            isOncePurchased = true
            return
        }

        guard transaction.productID == Self.monthlyProductID,
              let expirationDate = transaction.expirationDate,
              expirationDate > Date()
        else { return }

        isMonthlySubscriptionActive = true
        subscriptionExpiryDate = expirationDate

        if transaction.offerType == .introductory {
            isTrialActive = true
        }
    }

    @MainActor
    func purchase(_ productID: String) async {
        let product: Product?
        if productID == Self.monthlyProductID {
            product = monthlyProduct
        } else {
            product = onceProduct
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
