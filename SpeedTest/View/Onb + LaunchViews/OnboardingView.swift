import SwiftUI
internal import StoreKit
import ApphudSDK


struct OnboardingView: View {
    @StateObject private var viewModel = OnbViewModel()
    @Environment(\.dismiss) private var dismiss
    @State var isDismissAllowed: Bool = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPriceLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var yearlyPrice: String = ""
    @State private var step: Int = 0
    
    let titles: [Text] = [
        Text("Check your \n".localized.capitalized).foregroundColor(.white)
        +
        Text("Internet Speed".localized.capitalized).foregroundColor(Color(hex: "#4599F5")),
        
        Text("Run a ".localized.capitalized).foregroundColor(.white)
        +
        Text("diagnostic ".localized.capitalized).foregroundColor(Color(hex: "#4599F5"))
        +
        Text("on\n your internet".localized.capitalized).foregroundColor(.white),
        
        Text("Loved ".localized.capitalized).foregroundColor(.white)
        +
        Text("by thousands\n".localized.capitalized).foregroundColor(Color(hex: "#4599F5"))
        +
        Text("of users".localized.capitalized).foregroundColor(.white),
        
        Text("Save ".localized.capitalized).foregroundColor(Color(hex: "#4599F5"))
        +
        Text("Your Network\n Test Results".localized.capitalized).foregroundColor(.white),
        
        Text("How do you ".localized.capitalized).foregroundColor(.white)
        +
        Text("connect\n".localized.capitalized).foregroundColor(Color(hex: "#4599F5"))
        +
        Text("to the internet?".localized.capitalized).foregroundColor(.white),
        
        Text("How often ".localized.capitalized).foregroundColor(Color(hex: "#4599F5"))
        +
        Text("do you\n test your speed?".localized.capitalized).foregroundColor(.white),
        
        Text("Upgrade ".localized.capitalized).foregroundColor(Color(hex: "#4599F5"))
        +
        Text("to the full\n version".localized.capitalized).foregroundColor(.white)
    ]
    
    let subtitles: [String] = [
        "Find out your download and upload\n speeds in seconds",
        "Scan your network security and find\n the best access points",
        "Real reviews from users who loved\n our product from day one",
        "Compare Wi-Fi, mobile, and \nmore — save every speed test",
        "Indicate which connection you \nuse most often",
        "Indicate which connection you \nuse most often",
        "Your answer helps us show the \nmost useful insights",
        "Treat yourself to stable, fast internet—without ads—for only "
    ]

    var body: some View {
        ZStack {
            back
            VStack {
                VStack {
                    titleView
                        .frame(maxHeight: 110)
                    Spacer(minLength: 10)
                    centerContent
                        .frame(maxHeight: .infinity)
                }
                .padding(.top, UIScreen.main.bounds.height / 23)
                
                Spacer(minLength: 10)
                bottomButtons
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationBarBackButtonHidden()
        .onChange(of: subscriptionManager.isSubscribed) { isSubscribed in
            if isSubscribed {
                NavigationManager.shared.push(TabView())
            }
        }
        .onAppear {
            loadPrices()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK".localized, role: .cancel) {
                
            }

        } message: {
            Text(alertMessage)
        }
    }
    
    private var back: some View {
        Color(hex: "#040A15")
            .ignoresSafeArea()
    }

    private var titleView: some View {
        VStack(spacing: 4) {
            titles[step]
                .font(.poppins(.bold, size: 25))
                .multilineTextAlignment(.center)
                .frame(height: 75)

            if step == 6 {
                if isPriceLoading {
                    Text("•••/year")
                        .font(.poppins(.medium, size: 14))
                        .foregroundStyle(Color(hex: "#787F88"))
                        .shimmer()
                } else {
                    Text("\("Treat yourself to stable, fast internet—without ads—for only".localized) \(yearlyPrice) \("per".localized) \("year".localized)")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(hex: "#787F88"))
                        .font(.poppins(.medium, size: 14))
                        .frame(height: 42)
                        .padding(.horizontal, 40)
                }
            } else {
                Text(subtitles[step])
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.poppins(.medium, size: 14))
                    .frame(height: 42)
                    .padding(.horizontal, 40)
            }
        }
    }

    private var centerContent: some View {
        VStack {
            if step == 0 || step == 1 || step == 2 || step == 3 || step == 6 {
                Image("onb\(step)")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, (UIScreen.main.bounds.height <= 667) ? -70 : 0)
            } else if step == 4 || step == 5 {
                setupSelectionView(isInitial: step == 4)
            }
            
            Button {
                if step == 6 {
                    Task {
                        guard let paywall = subscriptionManager.paywall else {
                            await subscriptionManager.fetchPaywall()
                            return
                        }

                        if let product = paywall.products.first(where: {
                            subscriptionManager.getProductType($0) == "yearly"
                        }) {
                            let success = await subscriptionManager.purchase(product: product)
                            if success {
                                NavigationManager.shared.push(TabView())
                            }
                        }
                    }
                } else {
                    if step < 6  {
                        step += 1
                    }

                    if step == 2 {
                        if let scene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }
                }
            } label: {
                ZStack {
                    Capsule()
                        .frame(height: 70)
                        .frame(width: UIScreen.main.bounds.width - 36)
                        .foregroundStyle(LinearGradient.appBlueGradient.opacity(viewModel.showActive(step: step) ? 1 : 0.5))
                        .shadow(color: viewModel.showActive(step: step) ? Color(hex: "#245BEB").opacity(0.47) : .clear, radius: 10, x: 0, y: 4)
                        .shadow(color: (UIScreen.main.bounds.height <= 667) ? .white.opacity(0.6) : .clear, radius: 8, x: 0, y: 4)
                    
                    Text("Continue".localized)
                        .foregroundStyle(.white.opacity(viewModel.showActive(step: step) ? 1 : 0.5))
                        .font(.poppins(.bold, size: 18))
                }
                .padding(.bottom, 10)
                .padding(.top, -10)
            }
            .disabled(!viewModel.showActive(step: step))
        }
    }

    private var bottomButtons: some View {
        HStack(spacing: step == 6 ? 35 : 55) {
            Button {
                openURL(Config.privacy.rawValue)
            } label: {
                Text("Privacy".localized)
            }

            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore".localized)
            }

            Button {
                openURL(Config.terms.rawValue)
            } label: {
                Text("Terms".localized)
            }

            if step == 6 {
                Button {
                    if isDismissAllowed {
                        dismiss()
                    } else {
                        NavigationManager.shared.push(TabView())
                    }
                } label: {
                    Text("Not Now".localized)
                }
            }
        }
        .lineLimit(1)
        .foregroundStyle(Color(hex: "#787F88"))
        .font(.poppins(.medium, size: 12))
    }

    private func loadPrices() {
        isPriceLoading = true
        Task {
            await subscriptionManager.fetchPaywall()
            if let paywall = subscriptionManager.paywall {
                for product in paywall.products {
                    let price = subscriptionManager.formatPrice(product)
                    if subscriptionManager.getProductType(product) == "yearly" {
                        yearlyPrice = price
                    }
                }
            }
            isPriceLoading = false
        }
    }

    func restorePurchases() async {
        let success = await subscriptionManager.restorePurchases()
        await MainActor.run {
            if success {
                alertTitle = "Restore Successful".localized
                alertMessage = "Your previous purchases have been successfully restored.".localized
                showAlert = true
                NavigationManager.shared.push(TabView())
            } else {
                alertTitle = "Restore Failed".localized
                alertMessage = "No active subscription found or restore failed. Please try again later.".localized
                showAlert = true
            }
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    @ViewBuilder private func setupSelectionView(isInitial: Bool) -> some View {
        VStack {
            ForEach(0..<4) { i in
                Button {
                    if isInitial {
                        viewModel.howToConnectInternet = viewModel.connectionTypeTexts[i]
                    } else {
                        viewModel.testingFrequency = viewModel.testFrequencyTexts[i]
                    }
                } label: {
                    HStack(spacing: 12) {
                        if isInitial {
                            Image("howToConnect\(i)")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30, alignment: .center)
                        }
                        
                        Text(isInitial ? viewModel.connectionTypeTexts[i].localized : viewModel.testFrequencyTexts[i].localized)
                            .font(.poppins(.semibold, size: 18))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        if isInitial {
                            if viewModel.howToConnectInternet == nil {
                                Image(.unselectedCategoryIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 46, height: 46, alignment: .center)
                            } else if viewModel.howToConnectInternet == viewModel.connectionTypeTexts[i] {
                                ZStack {
                                    Image(.selectedCategoryIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 46, height: 46, alignment: .center)
                                }
                            }
                        } else {
                            if viewModel.testingFrequency == nil {
                                Image(.unselectedCategoryIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 46, height: 46, alignment: .center)
                            } else if viewModel.testingFrequency == viewModel.testFrequencyTexts[i] {
                                ZStack {
                                    Image(.selectedCategoryIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 46, height: 46, alignment: .center)
                                }
                            }
                        }
                    }
                    .frame(height: 66, alignment: .center)
                    .padding(.horizontal, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .foregroundStyle(Color(hex: "#292F38"))
                            .overlay(content: {
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke((viewModel.testingFrequency == viewModel.testFrequencyTexts[i] && !isInitial) || (viewModel.howToConnectInternet == viewModel.connectionTypeTexts[i] && isInitial) ? Color(hex: "#4599F5") : .clear, lineWidth: 2)
                                    .foregroundStyle((viewModel.testingFrequency == viewModel.testFrequencyTexts[i] && !isInitial) || (viewModel.howToConnectInternet == viewModel.connectionTypeTexts[i] && isInitial) ? Color(hex: "#4599F5").opacity(0.17) : .clear)
                            })
                    )
                    .overlay {
                        if (isInitial && viewModel.howToConnectInternet != nil) || (!isInitial && viewModel.testingFrequency != nil) {
                            RoundedRectangle(cornerRadius: 24)
                                .foregroundStyle((viewModel.testingFrequency == viewModel.testFrequencyTexts[i] && !isInitial) || (viewModel.howToConnectInternet == viewModel.connectionTypeTexts[i] && isInitial) ? .clear : Color(hex: "#292F38").opacity(0.7))
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 18)
    }
}

#Preview {
    NavigationView {
        OnboardingView()
    }
}
