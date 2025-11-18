import SwiftUI

struct SettingsView: View {
    @AppStorage("unit") private var unit: Int = 0
    let unitStrings: [String] = ["Mbit/s", "MB/s", "KB/s"]
    @AppStorage("dialScale") private var dialScale: Int = 0
    let dialScaleAmounts: [String] = ["1000", "500", "100"]
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showIconsSwitch: Bool = false
    @AppStorage("CurrentAppIcon") private var currentSelection: CustomAppIcon = .defaultIcon
    @Binding var tabAppears: Bool
    @State private var presentAlert: Bool = false
    @State private var isUnit: Bool = true

    var body: some View {
        ZStack {
            BackView()
            VStack(spacing: 20) {
                topView
                ScrollView {
                    VStack(spacing: 15) {
                        if !subscriptionManager.isSubscribed {
                            proButton
                                .padding(.bottom, 10)
                        }
                        
                        Button {
                            presentAlert = true
                            isUnit = true
                        } label: {
                            settingsCell(icon: .settingsUnitIcon, title: "Unit", unitString: unitStrings[unit])
                        }
                        .buttonStyle(HapticButtonStyle())

                        Button {
                            presentAlert = true
                            isUnit = false
                        } label: {
                            settingsCell(icon: .settingsDialScaleIcon, title: "Dial scale", unitString: dialScaleAmounts[dialScale])
                        }
                        .buttonStyle(HapticButtonStyle())

                        Button {
                            NavigationManager.shared.present(SubscriptionView(), isFullScreenCover: false, isCrossDissolve: false)
                        } label: {
                            settingsCell(icon: .settingsSubscriptionPlansIcon, title: "Subscription plans", unitString: nil)
                        }
                        .buttonStyle(HapticButtonStyle())

                        Button {
                            showIconsSwitch = true
                            tabAppears = false
                        } label: {
                            settingsCell(icon: .settingsFAQIcon, title: "Replace icon", unitString: nil)
                        }
                        .buttonStyle(HapticButtonStyle())

                        Button {
                            NavigationManager.shared.push(FAQView())
                        } label: {
                            settingsCell(icon: .settingsReplaceIconImace, title: "FAQ", unitString: nil)
                        }
                        .buttonStyle(HapticButtonStyle())

                        Button {
                            shareApp()
                        } label: {
                            settingsCell(icon: .settingsShareLinkImace, title: "Share link", unitString: nil)
                        }
                        .buttonStyle(HapticButtonStyle())

                        Button {
                            openURL(Config.privacy.rawValue)
                        } label: {
                            settingsCell(icon: .settingsPrivacyIcon, title: "Privacy Policy", unitString: nil)
                        }
                        .buttonStyle(HapticButtonStyle())

                        Button {
                            openURL(Config.terms.rawValue)
                        } label: {
                            settingsCell(icon: .settingsTermsIcon, title: "Terms of Use", unitString: nil)
                        }
                        .buttonStyle(HapticButtonStyle())
                    }
                    .padding(.vertical, 20)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal)
            if showIconsSwitch {
                switchIconsView
            }
            if presentAlert {
                CustomAlertView(
                    title: isUnit ? "Select a unit of measurement".localized : "Dial scale".localized,
                    options: isUnit ? unitStrings : dialScaleAmounts,
                    onSelect: { index in
                        if isUnit {
                            unit = index
                        } else {
                            dialScale = index
                        }
                    },
                    onDismiss: {
                        presentAlert = false
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .toolbar(showIconsSwitch ? .hidden : .visible, for: .tabBar)
        .navigationBarBackButtonHidden()
    }
    
    private var topView: some View {
        Text("Settings".localized)
            .foregroundStyle(.white)
            .font(.poppins(.semibold, size: 24))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var proButton: some View {
        Button {
            NavigationManager.shared.push(OnboardingView(isDismissAllowed: true, step: 6))
        } label: {
            Image(.settingsProButtonBack)
                .resizable()
                .scaledToFit()
                .overlay {
                    VStack(spacing: 10) {
                        VStack(spacing: 6) {
                            Text("Get Unlimited access".localized)
                                .font(.poppins(.bold, size: 24))
                                .foregroundStyle(.white)
                            Text("to all application features".localized)
                                .font(.poppins(.medium, size: 18))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 5)
                        Spacer()
                        Text("Start Now".localized)
                            .font(.poppins(.semibold, size: 18))
                            .foregroundStyle(Color(hex: "#00080B"))
                            .padding(.vertical, 14)
                            .padding(.horizontal)
                            .background(
                                Capsule()
                                    .foregroundStyle(.white)
                                    .shadow(color: Color(hex: "#00080B").opacity(0.2), radius: 9, x: 0, y: 8)
                            )
                            .padding(.bottom, 5)
                    }
                    .padding()
                }
                .shadow(color: Color(hex: "#245BEB").opacity(0.47), radius: 9.2, x: 0, y: 4)
            
        }
        .buttonStyle(HapticButtonStyle())
    }
    
    @ViewBuilder
    private func settingsCell(icon: ImageResource, title: String, unitString: String?) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30, alignment: .center)
            
            Text(title.localized)
                .font(.onest(.semibold, size: 18))
                .foregroundStyle(.white)
            Spacer()
            if let unitString {
                Text(unitString.localized)
                    .font(.poppins(.medium, size: 18))
                    .foregroundStyle(.white)
                Image(systemName: "chevron.down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 6, alignment: .center)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: "#787F88"))
            } else {
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 6, height: 12, alignment: .center)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: "#787F88"))
            }
        }
        .frame(height: 30)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .foregroundStyle(Color(hex: "#292F38"))
        )
    }
    
    private var switchIconsView: some View {
         ZStack(alignment: .bottom) {
             Rectangle()
                 .fill(.ultraThinMaterial)
                 .background(Color(hex: "#040A15").opacity(0.3))
                 .ignoresSafeArea()
                 .onTapGesture {
                     showIconsSwitch = false
                     tabAppears = true
                 }
             
             VStack(spacing: 20) {
                 HStack {
                     Spacer()
                     Button {
                         showIconsSwitch = false
                         tabAppears = true
                     } label: {
                         Image(.glassLiquidXButton)
                             .resizable()
                             .scaledToFit()
                             .frame(width: 36, height: 36, alignment: .center)
                             .padding()
                     }
                     .buttonStyle(HapticButtonStyle())
                 }
                 
                 Text("Replace icon".localized)
                     .foregroundStyle(.white)
                     .font(.poppins(.bold, size: 24))
                     .padding(.top, -30)
                 
                 HStack {
                     ForEach(CustomAppIcon.allCases) { icon in
                         Button {
                             withAnimation {
                                 currentSelection = icon
                                 AppIconManager.shared.setAppIcon(to: icon)
                                 UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                             }
                         } label: {
                             Image(icon == .defaultIcon ? .appIcon0 : .appIcon1)
                                 .resizable()
                                 .scaledToFit()
                                 .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: (UIScreen.main.bounds.width - 50) / 2)
                                 .clipShape(RoundedRectangle(cornerRadius: 21))
                                 .overlay {
                                     RoundedRectangle(cornerRadius: 20)
                                         .stroke(currentSelection == icon ? Color(hex: "#FFFFFF") : Color(hex: "#FFFFFF"), lineWidth: currentSelection == icon ? 4 : 0)
                                 }
                         }
                         .buttonStyle(HapticButtonStyle())

                     }
                 }
             }
             .padding(.vertical, 10)
             .padding(.bottom, 70)
             .background(
                 RoundedRectangle(cornerRadius: 38)
                     .foregroundStyle(Color(hex: "#040A15"))
             )
             .padding(.bottom, -70)
             .toolbar(.hidden, for: .tabBar)

         }
     }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func shareApp() {
        guard let url = URL(string: "https://apps.apple.com/app/id\(Config.appID.rawValue)") else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView(tabAppears: .constant(true))
    }
}
