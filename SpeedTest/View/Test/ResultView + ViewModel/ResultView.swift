import SwiftUI

struct ResultView: View {
    @State var testResults: TestResults
    @Environment(\.dismiss) private var dismiss
    @State private var byAverageValue: Double = 0.0
    
    @State private var watchVideosRating: Int = 0
    @State private var playGamesRating: Int = 0
    @State private var uploadPhotosRating: Int = 0
    @State private var showRateApp = false
    @State var action: (() -> Void)?
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @AppStorage("firstSpeedTest") private var firstSpeedTest: Bool = true
    @AppStorage("firstRateAppear") private var firstRateAppear: Bool = true

    var body: some View {
        ZStack {
            BackView()
            VStack {
                topView
                ScrollView {
                    VStack(spacing: 20) {
                        uploadDownloadView
                        secondInfoView
                        bandwidthView
                        connectionRatingView
                    }
                    .padding(.bottom, 130)
                }
            }
            .padding(.horizontal, 18)
            
        }
        .overlay(alignment: .bottom, content: {
            retryTestView
                .padding(.top, 30)
                .background(
                    Rectangle()
                        .ignoresSafeArea()
                        .foregroundStyle(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .bottom))
                )
            if firstRateAppear {
                RateAppView(isRateApp: $firstRateAppear)
            }
        })
        .navigationBarBackButtonHidden()
        .onAppear {
            watchVideosRating = testResults.watchVideosRating
            playGamesRating = testResults.playGamesRating
            uploadPhotosRating = testResults.uploadPhotosRating
            showRateApp = firstRateAppear
            firstSpeedTest = false
            byAverageValue = TestResultEntity.averageBandwidth()
            print("📊 Download history count: \(testResults.downloadHistory.count)")
            print("📊 Upload history count: \(testResults.uploadHistory.count)")
        }
    }
    
    private var topView: some View {
        HStack {
            Text("Result".localized)
                .foregroundStyle(.white)
                .font(.poppins(.semibold, size: 24))
            
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
    
    private var uploadDownloadView: some View {
        HStack(spacing: 10) {
            UploadDownloadView(
                isDownload: true,
                speed: .constant(testResults.downloadSpeed),
                isHistoryGiven: true,
                speedHistory: testResults.downloadHistory
            )
            UploadDownloadView(
                isDownload: false,
                isGreen: false,
                speed: .constant(testResults.uploadSpeed),
                isHistoryGiven: true,
                speedHistory: testResults.uploadHistory
            )
        }
    }
    
    private var secondInfoView: some View {
        VStack(spacing: 0) {
            secondInfoCell(title: "Ping".localized, measure: "\(testResults.ping)ms")
            Divider()
                .background(.white.opacity(0.25))
            secondInfoCell(title: "Provider".localized, measure: "\(testResults.serverLocation)")
            Divider()
                .background(.white.opacity(0.25))
            secondInfoCell(title: "Internal IP".localized, measure: "\(testResults.internalIP)")
            Divider()
                .background(.white.opacity(0.25))
            secondInfoCell(title: "External IP".localized, measure: "\(testResults.externalIP)")
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .foregroundStyle(Color(hex: "#292F38"))
        )
    }
    
    @ViewBuilder
    private func secondInfoCell(title: String, measure: String) -> some View {
        HStack(spacing: 15) {
            Text(title)
            Spacer()
            Text(measure)
        }
        .lineLimit(1)
        .padding(18)
        .font(.onest(.semibold, size: 18))
        .foregroundStyle(.white)
    }
    
    private var bandwidthView: some View {
        VStack(spacing: 15) {
            HStack {
                Image(.resultBandwidthIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24, alignment: .center)
                Text("Bandwidth".localized)
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.onest(.semibold, size: 18))
                Spacer()
            }
            
            VStack {
                HStack(alignment: .bottom, spacing: 15) {
                    Image(.resultRocket)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36, alignment: .center)
                    Text("\(String(format: "%.1f", testResults.bandwidth))")
                        .foregroundStyle(.white)
                        .font(.poppins(.semibold, size: 24))
                    Text("M")
                        .foregroundStyle(Color(hex: "#787F88"))
                        .font(.poppins(.semibold, size: 16))
                    Spacer()
                }
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .foregroundStyle(.white.opacity(0.15))
                    Capsule()
                        .foregroundStyle(Color(hex: "#4599F5"))
                        .frame(width: (UIScreen.main.bounds.width - 39) * min(testResults.bandwidth / 200.0, 1.0))
                }
                .frame(height: 20)
                
                Text("BY Average: \(String(format: "%.1f", byAverageValue))M".localized)
                    .foregroundStyle(.white.opacity(0.5))
                    .font(.onest(.medium, size: 16))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .foregroundStyle(Color(hex: "#292F38"))
            )
        }
    }
    
    private var connectionRatingView: some View {
        VStack(spacing: 15) {
            HStack {
                Image(.resultConnectionRatingIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24, alignment: .center)
                Text("Сonnection Rating".localized)
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.onest(.semibold, size: 18))
                Spacer()
            }
            
            VStack(spacing: 0) {
                connectionRatingCell(title: "Watch Videos".localized, measure: watchVideosRating)
                Divider()
                    .background(.white.opacity(0.25))
                connectionRatingCell(title: "Play Games".localized, measure: playGamesRating)
                Divider()
                    .background(.white.opacity(0.25))
                connectionRatingCell(title: "Upload Photos".localized, measure: uploadPhotosRating)
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .foregroundStyle(Color(hex: "#292F38"))
            )
        }
    }
    
    @ViewBuilder
    private func connectionRatingCell(title: String, measure: Int) -> some View {
        HStack {
            Text(title)
                .font(.onest(.semibold, size: 18))
                .foregroundStyle(.white)
            
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle((i < measure) ? Color(hex: "#4599F5") : .white.opacity(0.15))
                        .frame(width: 10, height: 23, alignment: .center)
                }
            }
        }
        .padding()
    }
    
    private var retryTestView: some View {
        VStack {
            Button {
                retryTest()
            } label: {
                ZStack {
                    Capsule()
                        .foregroundStyle(LinearGradient.appBlueGradient)
                    Text("Retry Test".localized)
                        .font(.onest(.semibold, size: 18))
                        .foregroundStyle(.white)
                }
                .frame(height: 62)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .buttonStyle(HapticButtonStyle())

            Text("A repeat test will give more accurate results".localized)
                .foregroundStyle(.white.opacity(0.5))
                .font(.onest(.medium, size: 14))
        }
    }
    
    private func retryTest() {
        dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: NSNotification.Name("StartSpeedTest"), object: nil)
        }
        if let action {
            if subscriptionManager.isSubscribed {
                action()
            } else if firstSpeedTest {
                firstSpeedTest = false
                action()
            } else {
                NavigationManager.shared.push(OnboardingView(isDismissAllowed: true, step: 6))
            }
        }
    }
}

#Preview {
    ResultView(testResults: TestResults(
        downloadSpeed: 52.3,
        uploadSpeed: 105.0,
        downloadHistory: [
            SpeedDataPoint(index: 0, speed: 20),
            SpeedDataPoint(index: 1, speed: 35),
            SpeedDataPoint(index: 2, speed: 45),
            SpeedDataPoint(index: 3, speed: 52),
            SpeedDataPoint(index: 4, speed: 50),
        ],
        uploadHistory: [
            SpeedDataPoint(index: 0, speed: 50),
            SpeedDataPoint(index: 1, speed: 75),
            SpeedDataPoint(index: 2, speed: 95),
            SpeedDataPoint(index: 3, speed: 105),
            SpeedDataPoint(index: 4, speed: 100),
        ],
        ping: 123,
        jitter: 3,
        packetLoss: 0,
        serverName: "Republican Unit",
        serverLocation: "New York, USA",
        connectionType: "Wi-Fi",
        providerName: "My Network",
        internalIP: "123.456.78.945",
        externalIP: "12.345.67.89",
        testDate: Date()
    ))
}
