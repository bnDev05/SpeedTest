import Foundation
import ApphudSDK
import Combine
internal import StoreKit

final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed = false
    @Published var paywall: ApphudPaywall?
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupApphud()
        checkSubscriptionStatus()
    }
    
    private func setupApphud() {
        NotificationCenter.default.addObserver(
            forName: Apphud.didUpdateNotification(),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkSubscriptionStatus()
        }
    }
    
    func checkSubscriptionStatus() {
        isSubscribed = Apphud.hasActiveSubscription()
//        isSubscribed = true
    }
    
    @MainActor
    func fetchPaywall() async {
        isLoading = true
        error = nil
        
        do {
            let placements = try await Apphud.placements(maxAttempts: 3)
            
            var selectedPaywall: ApphudPaywall?
            if let mainPlacement = placements.first(where: { $0.identifier == "main" }) {
                selectedPaywall = mainPlacement.paywall
            } else if let allPlacement = placements.first(where: { $0.identifier == "all" }) {
                selectedPaywall = allPlacement.paywall
            } else {
                selectedPaywall = placements.first?.paywall
            }
            
            #if DEBUG
            print("Placements found: \(placements.map { $0.identifier })")
            print("All paywall products: \(selectedPaywall?.products.map { $0.productId } ?? [])")
            #endif
            
            if let paywall = selectedPaywall {
                let validProducts = paywall.products.filter { product in
                    let isValid = product.skProduct != nil
                    #if DEBUG
                    if !isValid {
                        print("Filtering out invalid product: \(product.productId)")
                    }
                    #endif
                    return isValid
                }
                
                #if DEBUG
                print("Valid products after filtering: \(validProducts.map { $0.productId })")
                #endif
                
                let targetProducts = ["year.20.nt", "week.5.nt"]
                let filteredProducts = validProducts.filter { targetProducts.contains($0.productId) }
                
                if !filteredProducts.isEmpty {
                    self.paywall = paywall
                } else {
                    self.paywall = nil
                    error = "No valid products available. Products may not be set up correctly in App Store Connect."
                }
            } else {
                error = "No paywall found in placements"
            }
            
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("Failed to fetch paywall: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    func purchase(product: ApphudProduct) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            let result = try await Apphud.purchase(product)
            checkSubscriptionStatus()
            isLoading = false
            return result.success
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            #if DEBUG
            print("Purchase failed: \(error)")
            #endif
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        error = nil
        
        do {
            let result = try await Apphud.restorePurchases()
            checkSubscriptionStatus()

            let hasActiveSubscription = Apphud.hasActiveSubscription()
            if !hasActiveSubscription {
                print("[Apphud] Restore completed but no active subscription found.")
            }
            
            isLoading = false
            return hasActiveSubscription
            
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("[Apphud] Restore failed: \(error)")
            return false
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
