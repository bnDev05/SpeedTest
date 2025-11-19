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
                Image((UIScreen.main.bounds.height <= 667) ? .freeTrialForSE : .trialTop)
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
                
                (
                    Text("Start your ".localized)
                    .foregroundColor(.white)
                    .font(.poppins(.bold, size: 25))
                    +
                    Text("3-day free!".localized)
                        .foregroundColor(Color(hex: "#4599F5"))
                        .font(.poppins(.bold, size: 25))
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

                HStack(alignment: .top) {
                    Image(.trialLeft)
                    
                    VStack {
                        Text("Today: Get instant access".localized)
                            .foregroundStyle(.white)
                            .font(.poppins(.bold, size: 18))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        Text("Get access to all premium \nfeatures for free".localized)
                            .foregroundStyle(Color(hex: "#787F88"))
                            .font(.poppins(.medium, size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)
                        Text("Day 2: Trial reminder".localized)
                            .foregroundStyle(.white)
                            .font(.poppins(.bold, size: 18))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)

                        Text("We'll send you an email that your \ntrial is ending".localized)
                            .foregroundStyle(Color(hex: "#787F88"))
                            .font(.poppins(.medium, size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)

                        Text("Day 3: Full Subscription".localized)
                            .foregroundStyle(.white)
                            .font(.poppins(.bold, size: 18))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("You will be charged today, \ncancel anytime".localized)
                            .font(.poppins(.medium, size: 14))
                            .foregroundStyle(Color(hex: "#787F88"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)

                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, UIScreen.main.bounds.height / 35)
                .padding(.horizontal)
                
                Text("First 3 days free,".localized)
                    .foregroundStyle(.white)
                    .font(.poppins(.bold, size: 18))

                Text("\(String(format: "then %@ per Year.".localized, price)) \( "Cancel at anytime".localized )")
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.poppins(.medium, size: 14))
                    .padding(.bottom, (UIScreen.main.bounds.height <= 667) ? 0 : 20)
                
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
                        
                        Text("Continue".localized)
                            .foregroundStyle(.white)
                            .font(.poppins(.bold, size: 18))
                    }
                    .padding(.bottom, UIScreen.main.bounds.height / 30)
                    .padding(.top, 10)
                }
                .buttonStyle(HapticButtonStyle())

                bottomButtons
            }
        }
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 55) {
            Button {
                openURL(Config.privacy.rawValue)
            } label: {
                Text("Privacy")
            }
            .buttonStyle(HapticButtonStyle())

            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore")
            }
            .buttonStyle(HapticButtonStyle())

            Button {
                openURL(Config.terms.rawValue)
            } label: {
                Text("Terms")
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
