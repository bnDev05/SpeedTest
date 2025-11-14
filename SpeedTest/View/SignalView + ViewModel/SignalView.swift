//
//  SignalView.swift
//  SpeedTest
//
//  Created by Behruz Norov on 07/11/25.
//

import SwiftUI

struct SignalView: View {
    @StateObject private var viewModel = SignalViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @AppStorage("firstSignalTest") private var firstSignalTest: Bool = true
    var body: some View {
        ZStack {
            BackView()
            VStack {
                topView
                
                NetworkDiagnosticsView(action: {
                    if subscriptionManager.isSubscribed {
                        viewModel.startDiagnostic()
                    } else if firstSignalTest {
                        firstSignalTest = false
                        viewModel.startDiagnostic()
                    } else {
                        NavigationManager.shared.push(OnboardingView(isDismissAllowed: true, step: 6))
                    }
                }, progressPercentage: $viewModel.overallCompletedPercentage, diagnosticStatus: $viewModel.overallNetworkStatus)
                .frame(maxHeight: .infinity, alignment: .center)
                
                VStack(spacing: 10) {
                    NetworkItemView(
                        networkStatus: $viewModel.networkSettingsStatus,
                        isNetworkSettings: true,
                        icon: .networkSettingsIcon,
                        title: "Network Settings".localized,
                        subtitle: viewModel.networkName
                    )
                    
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    
                    NetworkItemView(
                        networkStatus: $viewModel.signalStrengthStatus,
                        icon: .signalStrengthIcon,
                        title: "Signal Strength".localized,
                        subtitle: viewModel.signalStrength
                    )
                    
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    
                    NetworkItemView(
                        networkStatus: $viewModel.dnsStatus,
                        icon: .dnsStatusIcon,
                        title: "DNS Status".localized,
                        subtitle: viewModel.dnsStatusText
                    )
                    
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    
                    NetworkItemView(
                        networkStatus: $viewModel.internetConnectionStatus,
                        icon: .internetConnectionStatusIcon,
                        title: "Internet Connection".localized,
                        subtitle: viewModel.internetConnectionText
                    )
                    
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    
                    NetworkItemView(
                        networkStatus: $viewModel.serverConnectionStatus,
                        icon: .serverConnectionIcon,
                        title: "Server Connection".localized,
                        subtitle: viewModel.serverConnectionText
                    )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .foregroundStyle(Color(hex: "#292F38"))
                )
                .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden()
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var topView: some View {
        HStack {
            Text("Network Diagnostic".localized)
                .foregroundStyle(.white)
                .font(.poppins(.semibold, size: 24))
                .frame(maxWidth: .infinity, alignment: .leading)
            if viewModel.overallNetworkStatus == 2 {
                Button {
                    viewModel.restartDiagnostic()
                } label: {
                    Image(.retestServerButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36, alignment: .center)
                }
                .buttonStyle(HapticButtonStyle())
            }
        }
    }
}

struct NetworkItemView: View {
    @Binding var networkStatus: Int // 0 = start, 1 = processing, 2 = completed
    var isNetworkSettings: Bool = false
    let icon: ImageResource
    let title: String
    let subtitle: String
    
    // local animation state
    @State private var rotationAngle: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading) {
                Text(title.localized)
                    .font(.onest(.semibold, size: 18))
                    .foregroundStyle(.white)
                
                if isNetworkSettings || networkStatus == 2 {
                    Text(subtitle)
                        .font(.onest(.medium, size: 14))
                        .foregroundStyle(Color(hex: "#787F88"))
                }
            }
            
            Spacer()
            
            if networkStatus == 1 {
                // Rotating icon while processing
                Image(.processIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        startRotation()
                    }
                    .onDisappear {
                        stopRotation()
                    }
            } else if networkStatus == 2 {
                Image(.signalCheckedIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
                    .padding(.trailing, -8)
            }
        }
        .frame(height: 46)
        .onChange(of: networkStatus) { newValue in
            if newValue == 1 {
                startRotation()
            } else {
                stopRotation()
            }
        }
    }
        
    private func startRotation() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            rotationAngle = -360
        }
    }
    
    private func stopRotation() {
        rotationAngle = 0
    }
}


#Preview {
    SignalView()
}
