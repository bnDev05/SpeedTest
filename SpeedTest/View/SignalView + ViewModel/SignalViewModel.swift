import SwiftUI
import Combine
import Network
import SystemConfiguration

final class SignalViewModel: ObservableObject {
    @Published var overallNetworkStatus: Int = 0 // 0 = idle, 1 = testing, 2 = complete
    @Published var overallCompletedPercentage: Int = 0
    @Published var networkSettingsStatus: Int = 0
    @Published var signalStrengthStatus: Int = 0
    @Published var dnsStatus: Int = 0
    @Published var internetConnectionStatus: Int = 0
    @Published var serverConnectionStatus: Int = 0
    
    // Status details
    @Published var networkName: String = "Network name".localized
    @Published var signalStrength: String = "Normal".localized
    @Published var dnsStatusText: String = "Normal".localized
    @Published var internetConnectionText: String = "Normal".localized
    @Published var serverConnectionText: String = "Normal".localized
    
    // Alert handling
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    private var progressTimer: Timer?
    
    func startDiagnostic() {
        // Reset all statuses
        resetStatuses()
        
        // Clean up any existing monitor
        cleanupMonitor()
        
        // Start the diagnostic sequence
        overallNetworkStatus = 1
        
        
        // Run diagnostics in sequence
        checkNetworkSettings()
    }
    
    func restartDiagnostic() {
        cleanupMonitor()
        progressTimer?.invalidate()
        
        // Small delay to ensure cleanup is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startDiagnostic()
        }
    }
    
    // MARK: - Private Methods
    
    private func cleanupMonitor() {
        monitor?.cancel()
        monitor = nil
    }
    
    private func resetStatuses() {
        overallCompletedPercentage = 0
        networkSettingsStatus = 0
        signalStrengthStatus = 0
        dnsStatus = 0
        internetConnectionStatus = 0
        serverConnectionStatus = 0
        
        networkName = "Network name".localized
        signalStrength = "Normal".localized
        dnsStatusText = "Normal".localized
        internetConnectionText = "Normal".localized
        serverConnectionText = "Normal".localized
    }
    
    private func checkNetworkSettings() {
        networkSettingsStatus = 1
        signalStrengthStatus = 1
        dnsStatus = 1
        internetConnectionStatus = 1
        serverConnectionStatus = 1
        animateProgress(to: 20, duration: 1.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Get actual network name
            let (hasNetwork, name) = self.getNetworkInfo()
            
            if hasNetwork {
                self.networkName = name
                self.networkSettingsStatus = 2
                self.checkSignalStrength()
            } else {
                self.networkName = "No network".localized
                self.networkSettingsStatus = 0
                self.showErrorAlert(
                    title: "Network Settings Error".localized,
                    message: "No active network interface detected. Please check your network connection.".localized
                )
                self.failDiagnostic()
            }
        }
    }
    
    private func checkSignalStrength() {
        signalStrengthStatus = 1
        animateProgress(to: 40, duration: 1.2)
        
        // Create a fresh monitor each time
        let newMonitor = NWPathMonitor()
        self.monitor = newMonitor
        
        var hasResponded = false
        
        newMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self, !hasResponded else { return }
            hasResponded = true
            
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    let strength = self.evaluateSignalStrength(path: path)
                    self.signalStrength = strength
                    self.signalStrengthStatus = 2
                    
                    // Stop this monitor before moving to next check
                    self.cleanupMonitor()
                    self.checkDNSStatus()
                } else {
                    self.signalStrength = "No signal".localized
                    self.signalStrengthStatus = 0
                    self.showErrorAlert(
                        title: "Signal Strength Error".localized,
                        message: "Network signal is not available. Please check your connection.".localized
                    )
                    self.cleanupMonitor()
                    self.failDiagnostic()
                }
            }
        }
        
        newMonitor.start(queue: monitorQueue)
        
        // Add timeout for signal strength check
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, !hasResponded else { return }
            hasResponded = true
            
            self.signalStrength = "Timeout".localized
            self.signalStrengthStatus = 0
            self.showErrorAlert(
                title: "Signal Strength Timeout".localized,
                message: "Unable to detect signal strength. Please try again.".localized
            )
            self.cleanupMonitor()
            self.failDiagnostic()
        }
    }
    
    private func checkDNSStatus() {
        dnsStatus = 1
        animateProgress(to: 60, duration: 1.0)
        
        // Test DNS resolution
        DispatchQueue.global().async {
            let (canResolveDNS, latency) = self.testDNSResolution()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if canResolveDNS {
                    self.dnsStatusText = latency < 50 ? "Excellent".localized : latency < 100 ? "Good".localized : "Normal".localized
                    self.dnsStatus = 2
                    self.checkInternetConnection()
                } else {
                    self.dnsStatusText = "Failed".localized
                    self.dnsStatus = 0
                    self.showErrorAlert(
                        title: "DNS Resolution Failed".localized,
                        message: "Unable to resolve domain names. Check your DNS settings.".localized
                    )
                    self.failDiagnostic()
                }
            }
        }
    }
    
    private func checkInternetConnection() {
        internetConnectionStatus = 1
        animateProgress(to: 80, duration: 1.3)
        
        // Test actual internet connectivity
        testInternetConnection { [weak self] success, speed in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                guard let self = self else { return }
                
                if success {
                    self.internetConnectionText = speed < 100 ? "Excellent".localized : speed < 300 ? "Good".localized : "Normal".localized
                    self.internetConnectionStatus = 2
                    self.checkServerConnection()
                } else {
                    self.internetConnectionText = "No connection".localized
                    self.internetConnectionStatus = 0
                    self.showErrorAlert(
                        title: "Internet Connection Failed".localized,
                        message: "Unable to connect to the internet. Please check your network.".localized
                    )
                    self.failDiagnostic()
                }
            }
        }
    }
    
    private func checkServerConnection() {
        serverConnectionStatus = 1
        animateProgress(to: 95, duration: 1.0)
        
        // Test connection to a speed test server
        testServerConnection { [weak self] success, latency in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard let self = self else { return }
                
                if success {
                    self.serverConnectionText = latency < 50 ? "Excellent".localized : latency < 150 ? "Good".localized : "Normal".localized
                    self.serverConnectionStatus = 2
                    self.completeDiagnostic()
                } else {
                    self.serverConnectionText = "Unreachable".localized
                    self.serverConnectionStatus = 0
                    self.showErrorAlert(
                        title: "Server Connection Failed".localized,
                        message: "Unable to reach speed test server. Please try again later.".localized
                    )
                    self.failDiagnostic()
                }
            }
        }
    }
    
    private func completeDiagnostic() {
        animateProgress(to: 100, duration: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.overallNetworkStatus = 2
            self.cleanupMonitor()
            self.progressTimer?.invalidate()
        }
    }
    
    private func failDiagnostic() {
        progressTimer?.invalidate()
        overallNetworkStatus = 0
        cleanupMonitor()
    }
    
    private func showErrorAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func animateProgress(to target: Int, duration: Double) {
        progressTimer?.invalidate()
        
        let startValue = overallCompletedPercentage
        let increment = target - startValue
        let steps = Int(duration * 30) 
        let stepIncrement = Double(increment) / Double(steps)
        var currentStep = 0
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { [weak self] timer in
            currentStep += 1
            let newValue = startValue + Int(stepIncrement * Double(currentStep))
            
            DispatchQueue.main.async {
                self?.overallCompletedPercentage = min(newValue, target)
            }
            
            if currentStep >= steps {
                timer.invalidate()
                DispatchQueue.main.async {
                    self?.overallCompletedPercentage = target
                }
            }
        }
    }
    
    // MARK: - Network Checks
    
    private func getNetworkInfo() -> (Bool, String) {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return (false, "No network".localized)
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return (false, "No network".localized)
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let isConnected = isReachable && !needsConnection
        
        if !isConnected {
            return (false, "No network".localized)
        }
        
        // Try to get WiFi network name
        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for interface in interfaces {
                if let networkInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                   let ssid = networkInfo[kCNNetworkInfoKeySSID as String] as? String {
                    return (true, ssid)
                }
            }
        }
        
        // If WiFi name not available, check connection type
        if flags.contains(.isWWAN) {
            return (true, "Cellular".localized)
        }
        
        return (true, "Connected".localized)
    }
    
    private func evaluateSignalStrength(path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "Good".localized // Could be enhanced with CoreWLAN on macOS
        } else if path.usesInterfaceType(.cellular) {
            return "Normal".localized
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "Excellent".localized
        }
        return "Normal".localized
    }
    
    private func testDNSResolution() -> (Bool, Int) {
        let startTime = Date()
        
        let host = CFHostCreateWithName(nil, "www.google.com" as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as? [Data] {
            let latency = Int(Date().timeIntervalSince(startTime) * 1000) // Convert to ms
            return (!addresses.isEmpty, latency)
        }
        return (false, 0)
    }
    
    private func testInternetConnection(completion: @escaping (Bool, Int) -> Void) {
        guard let url = URL(string: "https://www.google.com") else {
            completion(false, 0)
            return
        }
        
        let startTime = Date()
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let latency = Int(Date().timeIntervalSince(startTime) * 1000)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                completion(true, latency)
            } else {
                completion(false, 0)
            }
        }.resume()
    }
    
    private func testServerConnection(completion: @escaping (Bool, Int) -> Void) {
        guard let url = URL(string: "https://speed.cloudflare.com") else {
            completion(false, 0)
            return
        }
        
        let startTime = Date()
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let latency = Int(Date().timeIntervalSince(startTime) * 1000)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                completion(true, latency)
            } else {
                completion(false, 0)
            }
        }.resume()
    }
}
