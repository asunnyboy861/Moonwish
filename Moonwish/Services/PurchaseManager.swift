import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published private(set) var isPlus: Bool = false
    @Published private(set) var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var loadError: String?
    @Published var boosterBalance: Int = CloudQuotaService.shared.boosterBalance

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var monthlyProduct: Product? {
        products.first { $0.id == AppConfig.monthlyProductId }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == AppConfig.yearlyProductId }
    }

    var boosterProduct: Product? {
        products.first { $0.id == AppConfig.boosterProductId }
    }

    func loadProducts() async {
        isLoading = true
        loadError = nil
        do {
            products = try await Product.products(for: [
                AppConfig.monthlyProductId,
                AppConfig.yearlyProductId,
                AppConfig.boosterProductId
            ]).sorted { lhs, rhs in
                lhs.price < rhs.price
            }
            isLoading = false
        } catch {
            loadError = "Unable to load subscription options right now."
            isLoading = false
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    loadError = "Purchase could not be verified."
                    return false
                }
                if transaction.productID == AppConfig.boosterProductId {
                    CloudQuotaService.shared.addBooster(30)
                    boosterBalance = CloudQuotaService.shared.boosterBalance
                }
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil else { continue }
            if transaction.productID == AppConfig.monthlyProductId || transaction.productID == AppConfig.yearlyProductId {
                active = true
            }
        }
        isPlus = active
        boosterBalance = CloudQuotaService.shared.boosterBalance
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == AppConfig.boosterProductId {
                    await MainActor.run {
                        CloudQuotaService.shared.addBooster(30)
                        self?.boosterBalance = CloudQuotaService.shared.boosterBalance
                    }
                }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }
}
