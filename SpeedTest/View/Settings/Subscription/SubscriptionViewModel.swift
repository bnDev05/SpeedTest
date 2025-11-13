import SwiftUI
import Combine
import ApphudSDK
internal import StoreKit

final class SubscriptionPlansViewModel: ObservableObject {
    @Published var subscriptionIndex: Int = 0
    @Published var selectedProduct: ApphudProduct?
    @Published var paywall: ApphudPaywall?
    @Published var allPaywall: ApphudPaywall?
    @Published var isLoading = false
    @Published var error: String?
    @Published var isShowingRateApp = false

    private let subscriptionManager = SubscriptionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        subscriptionManager.$paywall
            .sink { [weak self] paywall in
                self?.paywall = paywall
                if let firstProduct = self?.getValidProducts().first {
                    self?.selectedProduct = firstProduct
                }
            }
            .store(in: &cancellables)
        
        subscriptionManager.$isLoading
            .assign(to: &$isLoading)
        
        subscriptionManager.$error
            .assign(to: &$error)
    }
    
    private func getValidProducts() -> [ApphudProduct] {
        guard let paywall = paywall else { return [] }
        let targetProducts = ["year.20.nt", "week.5.nt"]
        return paywall.products.filter { product in
            targetProducts.contains(product.productId) && product.skProduct != nil
        }
    }
    
    func getAllPlacementProducts() -> [ApphudProduct] {
        guard let allPaywall = allPaywall else { return [] }
        return allPaywall.products.filter { product in
            product.skProduct != nil
        }
    }
    
    @MainActor
    func fetchPaywall() async {
        await subscriptionManager.fetchPaywall()
    }
    
    @MainActor
    func fetchAllPaywall() async {
        isLoading = true
        error = nil
        
        Apphud.fetchPlacements { [weak self] placements, fetchError in
            guard let self = self else { return }
            
            if let fetchError = fetchError {
                self.error = fetchError.localizedDescription
                self.isLoading = false
                return
            }
            
            if let allPlacement = placements.first(where: { $0.identifier == "all" }) {
                self.allPaywall = allPlacement.paywall
                
                if self.selectedProduct == nil, let firstProduct = self.getAllPlacementProducts().first {
                    self.selectedProduct = firstProduct
                }
            } else {
                self.error = "Failed to find 'all' placement"
            }
            
            self.isLoading = false
        }
    }
    
    func purchaseSelectedPlan() async {
        guard let product = selectedProduct else {
            error = "Please select a subscription plan".localized
            return
        }
        
        let success = await subscriptionManager.purchase(product: product)
        
        if success {
            isShowingRateApp = true
        }
    }
    
    func restorePurchases() async {
        let success = await subscriptionManager.restorePurchases()
        if success {
            isShowingRateApp = true
        }
    }
    
    func formatPrice(_ product: ApphudProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.skProduct?.priceLocale
        return formatter.string(from: product.skProduct?.price ?? 0) ?? "$0.00"
    }
    
    func getProductType(_ product: ApphudProduct) -> String {
        if product.productId.contains("yearly") || product.productId.contains("annual") || product.productId.contains("year") {
            return "yearly"
        } else {
            return "weekly"
        }
    }
}
