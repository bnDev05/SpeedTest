import SwiftUI
import Combine

final class SignalViewModel: ObservableObject {
    @Published var overallNetworkStatus: Int = 0
    @Published var overallCompletedPercentage: Int = 0
    @Published var networkSettingsStatus: Int = 0
    @Published var signalStrengthStatus: Int = 0
    @Published var dnsStatus: Int = 0
    @Published var internetConnectionStatus: Int = 0
    @Published var serverConnectionStatus: Int = 0
}
