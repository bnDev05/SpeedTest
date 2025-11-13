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
                    
                        Button {
                            presentAlert = true
                            isUnit = false
                        } label: {
                            settingsCell(icon: .settingsDialScaleIcon, title: "Dial scale", unitString: dialScaleAmounts[dialScale])
                        }
                        
                        Button {
                            
                        } label: {
                            settingsCell(icon: .settingsSubscriptionPlansIcon, title: "Subscription plans", unitString: nil)
                        }
                        
                        Button {
                            showIconsSwitch = true
                            tabAppears = false
                        } label: {
                            settingsCell(icon: .settingsFAQIcon, title: "Replace icon", unitString: nil)
                        }
                        
                        Button {
                            
                        } label: {
                            settingsCell(icon: .settingsReplaceIconImace, title: "FAQ", unitString: nil)
                        }
                        
                        Button {
                            shareApp()
                        } label: {
                            settingsCell(icon: .settingsShareLinkImace, title: "Share link", unitString: nil)
                        }
                        
                        Button {
                            openURL(Config.privacy.rawValue)
                        } label: {
                            settingsCell(icon: .settingsPrivacyIcon, title: "Privacy Policy", unitString: nil)
                        }
                        
                        Button {
                            openURL(Config.terms.rawValue)
                        } label: {
                            settingsCell(icon: .settingsTermsIcon, title: "Terms of Use", unitString: nil)
                        }
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
                    title: isUnit ? "Select a unit of measurement" : "Dial scale",
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
//        .alert(isUnit ? "Select a unit of measurement" : "Dial scale", isPresented: $presentAlert) {
//            Button(isUnit ? "Mbit/s" : "1000") {
//                if isUnit {
//                    unit = 0
//                } else {
//                    dialScale = 0
//                }
//            }
//            Button(isUnit ? "MB/s" : "500") {
//                if isUnit {
//                    unit = 1
//                } else {
//                    dialScale = 1
//                }
//            }
//            Button(isUnit ? "KB/s" : "100") {
//                if isUnit {
//                    unit = 2
//                } else {
//                    dialScale = 2
//                }
//            }
//        }
        .toolbar(showIconsSwitch ? .hidden : .visible, for: .tabBar)
        .navigationBarBackButtonHidden()
    }
    
    private var topView: some View {
        Text("Settings")
            .foregroundStyle(.white)
            .font(.poppins(.semibold, size: 24))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var proButton: some View {
        Button {
            
        } label: {
            Image(.settingsProButtonBack)
                .resizable()
                .scaledToFit()
                .overlay {
                    VStack(spacing: 10) {
                        VStack(spacing: 6) {
                            Text("Get Unlimited access")
                                .font(.poppins(.bold, size: 22))
                                .foregroundStyle(.white)
                            Text("to all application features")
                                .font(.poppins(.medium, size: 17))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("Start Now")
                            .font(.poppins(.semibold, size: 18))
                            .foregroundStyle(Color(hex: "#00080B"))
                            .padding(.vertical, 14)
                            .padding(.horizontal)
                            .background(
                                Capsule()
                                    .foregroundStyle(.white)
                                    .shadow(color: Color(hex: "#00080B").opacity(0.2), radius: 9, x: 0, y: 8)
                            )
                    }
                    .padding()
                }
                .shadow(color: Color(hex: "#245BEB").opacity(0.47), radius: 9.2, x: 0, y: 4)
            
        }
    }
    
    @ViewBuilder
    private func settingsCell(icon: ImageResource, title: String, unitString: String?) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30, alignment: .center)
            
            Text(title)
                .font(.onest(.semibold, size: 18))
                .foregroundStyle(.white)
            Spacer()
            if let unitString {
                Text(unitString)
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
                 }
                 
                 Text("Replace icon".localized)
                     .foregroundStyle(.white)
                     .font(.poppins(.bold, size: 24))
                     .padding(.top, -30)
                 
                 HStack {
                     ForEach(CustomAppIcon.allCases) { icon in
                         Image(icon == .defaultIcon ? .appIcon0 : .appIcon1)
                             .resizable()
                             .scaledToFit()
                             .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: (UIScreen.main.bounds.width - 50) / 2)
                             .clipShape(RoundedRectangle(cornerRadius: 21))
                             .overlay {
                                 RoundedRectangle(cornerRadius: 20)
                                     .stroke(currentSelection == icon ? Color(hex: "#FFFFFF") : Color(hex: "#FFFFFF"), lineWidth: currentSelection == icon ? 4 : 0)
                             }
                             .onTapGesture {
                                 withAnimation {
                                     currentSelection = icon
                                     AppIconManager.shared.setAppIcon(to: icon)
                                     UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                 }
                             }
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
    SettingsView(tabAppears: .constant(true))
}
