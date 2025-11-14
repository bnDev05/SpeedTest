import SwiftUI
import ApphudSDK

struct TrialView: View {
    let price: String
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    let onDismiss: (() -> Void)
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            BackView()
            VStack(spacing: 0) {
                Image(.trialTop)
                    .resizable()
                    .scaledToFit()
                    .overlay(alignment: .topTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(.glassLiquidXButton)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36, alignment: .center)
                                .padding()
                        }
                        .buttonStyle(HapticButtonStyle())

                    }
                
                Text("Start your ".localized)
                    .foregroundColor(.white)
                    .font(.poppins(.bold, size: 25))
                +
                Text("3-day free!".localized)
                    .foregroundColor(Color(hex: "#4599F5"))
                    .font(.poppins(.bold, size: 25))
                
                HStack {
                    Image(.trialLeft)
                    
                    VStack {
                        Text("Today: Get instant access".localized)
                            .foregroundStyle(.white)
                            .font(.poppins(.bold, size: 18))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Get access to all premium \nfeatures for free".localized)
                            .foregroundStyle(Color(hex: "#787F88"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Day 2: Trial reminder".localized)
                            .foregroundStyle(.white)
                            .font(.poppins(.bold, size: 18))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("We’ll send you an email that your \ntrial is ending".localized)
                            .foregroundStyle(Color(hex: "#787F88"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Day 3: Full Subscription".localized)
                            .foregroundStyle(.white)
                            .font(.poppins(.bold, size: 18))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("You will be charged today, \ncancel anytime".localized)
                            .foregroundStyle(Color(hex: "#787F88"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.horizontal)
                
                Text("First 3 days free, ".localized)
                    .foregroundStyle(.white)
                    .font(.poppins(.bold, size: 18))
                Text("then \(price) per Year. Cancel at anytime".localized)
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.poppins(.medium, size: 14))
                
                Button {
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
                } label: {
                    ZStack {
                        Capsule()
                            .frame(height: 70)
                            .frame(width: UIScreen.main.bounds.width - 36)
                            .foregroundStyle(LinearGradient.appBlueGradient)
                            .shadow(color: Color(hex: "#245BEB").opacity(0.47), radius: 10, x: 0, y: 4)
                            .shadow(color: (UIScreen.main.bounds.height <= 667) ? .white.opacity(0.6) : .clear, radius: 8, x: 0, y: 4)
                        
                        Text("Continue".localized)
                            .foregroundStyle(.white)
                            .font(.poppins(.bold, size: 18))
                    }
                    .padding(.bottom, 10)
                    .padding(.top, 10)
                }
                .buttonStyle(HapticButtonStyle())

                bottomButtons
            }
        }
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 35) {
            Button {
                openURL(Config.privacy.rawValue)
            } label: {
                Text("Privacy".localized)
            }
            .buttonStyle(HapticButtonStyle())

            Button {
                Task {
                    await restorePurchases()
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

            Button {
                dismiss()
                onDismiss()
            } label: {
                Text("Not Now".localized)
            }
            .buttonStyle(HapticButtonStyle())
        }
        .lineLimit(1)
        .foregroundStyle(Color(hex: "#787F88"))
        .font(.poppins(.medium, size: 12))
    }
    
    func restorePurchases() async {
        let success = await subscriptionManager.restorePurchases()
        await MainActor.run {
            if success {
                alertTitle = "Restore Successful".localized
                alertMessage = "Your previous purchases have been successfully restored.".localized
                showAlert = true
                dismiss()
                onDismiss()
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
}

#Preview {
    TrialView(price: "19.99", onDismiss: {})
}
