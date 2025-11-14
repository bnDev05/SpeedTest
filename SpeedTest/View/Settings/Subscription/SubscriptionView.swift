import SwiftUI
import ApphudSDK
import Combine
internal import StoreKit

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionPlansViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            BackView()
            VStack {
                topView
                    .padding(.horizontal)

                if viewModel.isLoading {
                    loadingView
                } else if let allPaywall = viewModel.allPaywall, !allPaywall.products.isEmpty {
                    centerContentAllPlacement(paywall: allPaywall)
                    tryForFreeButton
                        .padding(.horizontal)

                    bottomButtons
                        .padding(.horizontal)

                } else if let paywall = viewModel.paywall, !paywall.products.isEmpty {
                    centerContent(paywall: paywall)
                    tryForFreeButton
                        .padding(.horizontal)
                    bottomButtons
                        .padding(.horizontal)
                } else {
                    errorView
                        .padding(.horizontal)
                }
            }
            .padding(.top)
            if viewModel.isShowingRateApp {
                RateAppView(isRateApp: $viewModel.isShowingRateApp)

            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            Task {
                await viewModel.fetchPaywall()
                await viewModel.fetchAllPaywall()
            }
        }
    }

    
    private var topView: some View {
        VStack(spacing: 25) {
            Capsule()
                .foregroundStyle(.gray.opacity(0.6))
                .frame(width: 45, height: 6, alignment: .center)
            HStack {
                Text("Subscription plans".localized)
                    .foregroundStyle(.white)
                    .font(.poppins(.bold, size: 28))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(.glassLiquidXButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36, alignment: .center)
                }
                .buttonStyle(HapticButtonStyle())

            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "#3795FB"))
            
            Text("Loading subscription plans...".localized)
                .font(.poppins(.medium, size: 16))
                .foregroundColor(Color(hex: "#969DA3"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#FF6B6B"))
            
            Text("Failed to load subscription plans".localized)
                .font(.poppins(.semibold, size: 18))
                .foregroundColor(Color(hex: "#010A13"))
            
            if let error = viewModel.error {
                Text(error)
                    .font(.poppins(.medium, size: 14))
                    .foregroundColor(Color(hex: "#969DA3"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Text("Please check:".localized)
                .font(.poppins(.semibold, size: 14))
                .foregroundColor(Color(hex: "#010A13"))
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Product IDs match in App Store Connect".localized)
                Text("• Products are approved and available".localized)
                Text("• Apphud dashboard has correct product IDs".localized)
                Text("• Using correct placement identifier".localized)
            }
            .font(.poppins(.regular, size: 12))
            .foregroundColor(Color(hex: "#969DA3"))
            
            Button("Retry".localized) {
                Task {
                    await viewModel.fetchPaywall()
                    await viewModel.fetchAllPaywall()
                }
            }
            .buttonStyle(HapticButtonStyle())
            .foregroundColor(Color(hex: "#3795FB"))
            .font(.poppins(.semibold, size: 16))
            .padding(.top)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func centerContent(paywall: ApphudPaywall) -> some View {
        let targetProducts = ["year.20.nt", "week.5.nt"]
        let validProducts = paywall.products.filter { product in
            targetProducts.contains(product.productId) && product.skProduct != nil
        }
        
        return ScrollView {
            VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        featuresCell(title: "Unlimited number of tests".localized, icon: .subscription0Icon)
                        featuresCell(title: "More accurate results".localized, icon: .subscription1Icon)
                        featuresCell(title: "Ad-Free experience".localized, isDividerAdd: false, icon: .subscription2Icon)
                    }
                    .padding(.horizontal)

                if validProducts.isEmpty {
                    Text("No valid subscription products available".localized)
                        .font(.poppins(.medium, size: 14))
                        .foregroundColor(Color(hex: "#969DA3"))
                        .padding()
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(validProducts.enumerated()), id: \.element.productId) { index, product in
                            Button {
                                viewModel.subscriptionIndex = index
                                viewModel.selectedProduct = product
                            } label: {
                                let productType = viewModel.getProductType(product)
                                let title = productType == "yearly" ? "yearly".localized : "3_day_free_trial".localized
                                let price = viewModel.formatPrice(product)
                                plansCell(title: title, price: "\(price)/\(productType == "yearly" ? "year".localized.capitalized : "week".localized.capitalized)", isSelected: (viewModel.selectedProduct?.productId == product.productId))
                            }
                            .buttonStyle(HapticButtonStyle())
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func centerContentAllPlacement(paywall: ApphudPaywall) -> some View {
        let validProducts = paywall.products.filter { product in
            product.skProduct != nil
        }
        
        return ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    featuresCell(title: "Unlimited number of tests".localized, icon: .subscription0Icon)
                    featuresCell(title: "More accurate results".localized, icon: .subscription1Icon)
                    featuresCell(title: "Ad-Free experience".localized, isDividerAdd: false, icon: .subscription2Icon)
                }
                .padding(.horizontal)

                if validProducts.isEmpty {
                    Text("No valid subscription products available".localized)
                        .font(.poppins(.medium, size: 14))
                        .foregroundColor(Color(hex: "#969DA3"))
                        .padding()
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(validProducts.enumerated()), id: \.element.productId) { index, product in
                            Button {
                                viewModel.subscriptionIndex = index
                                viewModel.selectedProduct = product
                            } label: {
                                let title = getTitleForProduct(product)
                                let priceWithPeriod = formattedPriceWithPeriod(for: product)
                                plansCell(title: title, price: priceWithPeriod, isSelected: (viewModel.selectedProduct?.productId == product.productId))

                            }
                            .buttonStyle(HapticButtonStyle())

                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    func getTitleForProduct(_ product: ApphudProduct) -> String {
        guard let period = product.skProduct?.subscriptionPeriod else {
            return "one_time"
        }

        switch period.unit {
        case .day:
            if period.numberOfUnits == 7 {
                return "weekly".localized
            } else {
                return "daily".localized
            }
        case .week:
            return "weekly".localized
        case .month:
            return period.numberOfUnits == 12 ? "yearly".localized : "monthly".localized
        case .year:
            return "yearly".localized
        @unknown default:
            return "unknown"
        }
    }

    
    private func formattedPriceWithPeriod(for product: ApphudProduct) -> String {
        let price = viewModel.formatPrice(product)
        
        if let period = product.skProduct?.subscriptionPeriod {
            let unit: String
            switch period.unit {
            case .day:
                if period.numberOfUnits == 7 {
                    unit = "week".localized
                } else {
                    unit = "day".localized
                }
            case .week:
                unit = "week".localized
            case .month:
                unit = period.numberOfUnits == 12 ? "year".localized : "month".localized
            case .year:
                unit = "year".localized
            @unknown default:
                unit = ""
            }
            return "\(price)/\(unit)"
        } else {
            return price
        }
    }
    
    @ViewBuilder
    func featuresCell(title: String, isDividerAdd: Bool = true, icon: ImageResource) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25, alignment: .center)
            Text(title.localized)
                .foregroundStyle(.white)
                .font(.poppins(.medium, size: 16))
            
            Spacer()
        }
        .padding(.bottom, isDividerAdd ? 12 : 0)
        .overlay(alignment: .bottom) {
            if isDividerAdd {
                Divider()
                    .background(.white.opacity(0.25))
                    .frame(height: 1)
            }
        }
    }
    
    @ViewBuilder
    func plansCell(title: String, price: String, isSelected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.capitalized.localized)
                    .font(.poppins(.bold, size: 18))
                    .foregroundStyle(.white)
                
                Text(price)
                    .font(.poppins(.medium, size: 16))
                    .foregroundStyle(Color(hex: "#787F88"))
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .frame(width: 30, height: 30, alignment: .center)
                    .foregroundStyle(isSelected ? LinearGradient.appBlueGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom))
                    .overlay {
                        Circle()
                            .stroke(isSelected ? .clear : .white.opacity(0.35), lineWidth: 2)
                    }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 10, alignment: .center)
                        .foregroundStyle(Color(hex: "#0F171A"))
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .padding(.vertical, -3)
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color(hex: "#4599F5") : Color.clear, lineWidth: isSelected ? 2 : 0)
                .padding(2)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(Color(hex: "#292F38"))
                .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 7)
        )
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 55) {
            Button {
                openURL(Config.privacy.rawValue)
            } label: {
                Text("Privacy".localized)
            }
            .buttonStyle(HapticButtonStyle())

            Button {
                Task {
                    await viewModel.restorePurchases()
                }
            } label: {
                Text("Restore".localized)
            }
            .buttonStyle(HapticButtonStyle())

            Button {
                openURL(Config.terms.rawValue)
            } label: {
                Text("Terms".localized)
            }
            .buttonStyle(HapticButtonStyle())
        }
        .foregroundStyle(Color(hex: "#B8B1AF"))
        .font(.poppins(.medium, size: 12))
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private var tryForFreeButton: some View {
        Button {
            Task {
                await viewModel.purchaseSelectedPlan()
            }
        } label: {
            ZStack {
                LinearGradient.appBlueGradient
                    .clipShape(Capsule())
                    .frame(height: 70)
                    .shadow(color: Color(hex: "#245BEB").opacity(0.25), radius: 9.2, x: 0, y: 4)
                Text("Try For Free".localized)
                    .font(.onest(.semibold, size: 18))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 20)
        }
        .buttonStyle(HapticButtonStyle())
        .disabled(viewModel.isLoading || viewModel.selectedProduct == nil)
        .opacity((viewModel.isLoading || viewModel.selectedProduct == nil) ? 0.6 : 1.0)
    }
}

#Preview {
    SubscriptionView()
}
