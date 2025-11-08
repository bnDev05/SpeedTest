import Combine
import SwiftUI
import ApphudSDK

final class OnbViewModel: ObservableObject {
    @Published var howToConnectInternet: String? = nil { didSet { save("connectionType", howToConnectInternet!) } }
    @Published var testingFrequency: String? = nil { didSet { save("testingFrequency", testingFrequency!) } }
    
    let connectionTypeTexts: [String] = ["Home Wi-Fi", "Mobile internet", "Wired connection", "Public Wi-Fi"]
    let testFrequencyTexts: [String] = ["First time", "Once a day or more often", "Several times a week", "Only when problems arise"]
    
    private func save(_ key: String, _ value: String) {
        Apphud.setUserProperty(key: .init(key), value: value, setOnce: false)
    }
    
    func showActive(step: Int) -> Bool {
        if step == 4 {
            return howToConnectInternet != nil
        } else if step == 5 {
            return testingFrequency != nil
        } else {
            return true
        }
    }
}
