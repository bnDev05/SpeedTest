import SwiftUI
import Combine

final class TestViewModel: ObservableObject {
    @Published var pingAmount: Int = 0 // in ms
    @Published var jitterAmount: Int = 0 // in ms
    @Published var lossAmount: Int = 0 // in percentage
    @Published var selectedUnit: String = "ms" // user selected unit
    @Published var speedState: SpeedTestState = .idle // the state of Speedometer
    @Published var speed: Double = 123.0 // in ms
    @Published var isConnected: Bool = true // there we should set the status of
    
    @Published var isWifiSource: Bool = true // there we should decide our internet source (Wi-Fi or Cellular)
    @Published var sourceName: String = "Comnet" // there we should set the name of source (Beeline, Comnet....)
    @Published var phoneName: String = "IPhone 13 Pro" // there we should set the name of source (IPhone 13 Pro...)
    
    @Published var serverName: String = "FiberNet" // server name
    @Published var serverLocationName: String = "Tashkent" // Server's location name

    func startTest() {
        speedState = .connecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.simulateSpeedTest()
        }
    }
    
    private func simulateSpeedTest() {
        var speed = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            speed += Double.random(in: 5...15)
            
            if speed >= 300 {
                timer.invalidate()
                self.speedState = .complete(speed: speed)
            } else {
                self.speedState = .testing(speed: speed)
            }
        }
    }
}
