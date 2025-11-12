//
//  SignalView.swift
//  SpeedTest
//
//  Created by Behruz Norov on 07/11/25.
//

import SwiftUI

struct SignalView: View {
    @StateObject private var viewModel = SignalViewModel()
    var body: some View {
        ZStack {
            BackView()
            VStack {
                topView
                
                NetworkDiagnosticsView(action: {
                    
                }, progressPercentage: $viewModel.overallCompletedPercentage, diagnosticStatus: $viewModel.overallNetworkStatus)
                .frame(maxHeight: .infinity, alignment: .center)
                
                VStack(spacing: 10) {
                    NetworkItemView(networkStatus: $viewModel.networkSettingsStatus, isNetworkSettings: true, icon: .networkSettingsIcon, title: "Network Settings", subtitle: "Network name")
                    
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    
                    NetworkItemView(networkStatus: $viewModel.signalStrengthStatus, icon: .signalStrengthIcon, title: "Signal Strength", subtitle: "Normal") // instead of these text, we should set actual condition of checking item
                    
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    
                    NetworkItemView(networkStatus: $viewModel.dnsStatus, icon: .dnsStatusIcon, title: "DNS Status", subtitle: "Normal") // instead of these text, we should set actual condition of checking item
                    
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    
                    NetworkItemView(networkStatus: $viewModel.internetConnectionStatus, icon: .internetConnectionStatusIcon, title: "Internet Connection", subtitle: "Normal") // instead of these text, we should set actual condition of checking item
                    
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    
                    NetworkItemView(networkStatus: $viewModel.serverConnectionStatus, icon: .serverConnectionIcon, title: "Server Connection", subtitle: "Normal") // instead of these text, we should set actual condition of checking item
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .foregroundStyle(Color(hex: "#292F38"))
                )
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden()
    }
    
    private var topView: some View {
        HStack {
            Text("Network Diagnostic")
                .foregroundStyle(.white)
                .font(.poppins(.semibold, size: 24))
                .frame(maxWidth: .infinity, alignment: .leading)
            if viewModel.overallNetworkStatus == 2 {
                Button {
                    
                } label: {
                    Image(.retestServerButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36, alignment: .center)
                }
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
                Text(title)
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
            }
        }
        .frame(height: 46)
        // If status changes dynamically (e.g. from 1→2), stop rotation automatically
        .onChange(of: networkStatus) { newValue in
            if newValue == 1 {
                startRotation()
            } else {
                stopRotation()
            }
        }
    }
    
    // MARK: - Rotation helpers
    
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
