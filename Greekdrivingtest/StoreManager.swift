import StoreKit
import Foundation

// MARK: - Product ID
// Create this product in App Store Connect → In-App Purchases → Add (Non-Consumable)
private let removeAdsProductID = "com.greekdrivingtest.removeads"

@Observable
class StoreManager {
    var product: Product?
    var adsRemoved: Bool = false
    var isPurchasing: Bool = false
    var errorMessage: String?

    init() {
        Task { await fetchProduct() }
        Task { await checkEntitlements() }
        Task { await listenForTransactions() }
    }

    @MainActor
    func fetchProduct() async {
        do {
            let products = try await Product.products(for: [removeAdsProductID])
            product = products.first
        } catch {}
    }

    @MainActor
    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == removeAdsProductID {
                adsRemoved = true
                return
            }
        }
    }

    @MainActor
    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    adsRemoved = true
                    await tx.finish()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        errorMessage = nil
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let tx) = result, tx.productID == removeAdsProductID {
                await MainActor.run { adsRemoved = true }
                await tx.finish()
            }
        }
    }
}
