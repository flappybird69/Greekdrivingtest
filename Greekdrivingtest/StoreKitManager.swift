import StoreKit

@Observable
final class StoreKitManager {
    nonisolated static let lifetimeProductID = "lifetime_unlock"
    private nonisolated static let firstLaunchKey = "firstLaunchDate"

    // MARK: - State
    let firstLaunchDate: Date
    private(set) var product: Product?
    private(set) var isPurchased = false
    private(set) var isLoading = false
    private(set) var purchaseError: String?

    @ObservationIgnored
    private var transactionListener: Task<Void, Never>?

    // MARK: - Trial

    private var elapsed: TimeInterval { Date().timeIntervalSince(firstLaunchDate) }
    var isTrialActive: Bool { elapsed < 3 * 86400 }
    var trialDaysRemaining: Int { max(0, 3 - Int(elapsed / 86400)) }
    var isUnlocked: Bool { isTrialActive || isPurchased }
    var displayPrice: String { product?.displayPrice ?? "€2.99" }

    // MARK: - Init

    init() {
        if let stored = UserDefaults.standard.object(forKey: Self.firstLaunchKey) as? Date {
            firstLaunchDate = stored
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: Self.firstLaunchKey)
            firstLaunchDate = now
        }

        transactionListener = Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let tx) = result, tx.productID == StoreKitManager.lifetimeProductID {
                    await MainActor.run { self.isPurchased = true }
                    await tx.finish()
                }
            }
        }

        Task { [weak self] in
            await self?.loadProducts()
            await self?.checkPurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - StoreKit

    @MainActor
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.lifetimeProductID])
            product = products.first
        } catch {}
    }

    @MainActor
    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == Self.lifetimeProductID {
                isPurchased = true
                return
            }
        }
    }

    @MainActor
    func purchase() async {
        guard let product else { return }
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    isPurchased = true
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
    func restorePurchases() async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
