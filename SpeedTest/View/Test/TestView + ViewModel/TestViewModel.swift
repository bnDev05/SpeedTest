import SwiftUI
import Combine
import CoreLocation

final class TestViewModel: NSObject, ObservableObject {
    @Published var pingAmount: Int = 0
    @Published var jitterAmount: Int = 0
    @Published var lossAmount: Int = 0
    @Published var selectedUnit: String = "ms"
    @Published var speedState: SpeedTestState = .idle
    @Published var speed: Double = 0
    @Published var isConnected: Bool = false
    
    @Published var isWifiSource: Bool = true
    @Published var sourceName: String = "Unknown"
    @Published var phoneName: String = ""
    
    @Published var serverName: String = "Loading..."
    @Published var serverLocationName: String = "..."
    
    @Published var isTestingStarted: Bool = false
    @Published var downloadSpeed: Double = 0.0
    @Published var uploadSpeed: Double = 0.0
    
    @Published var showErrorAlert: Bool = false
    
    // Store test results to pass to ResultView
    @Published var testResults: TestResults?
    
    // Store speed history for charts - these will be populated during test
    @Published var downloadSpeedHistory: [SpeedDataPoint] = []
    @Published var uploadSpeedHistory: [SpeedDataPoint] = []
    
    // IP addresses
    @Published var internalIP: String = ""
    @Published var externalIP: String = ""
    
    private let speedTestManager = SpeedTestManager.shared
    private let serverManager = ServerManager.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var currentLocation: CLLocation?
    
    override init() {
        super.init()
        setupBindings()
        setupLocationManager()
        updateConnectionInfo()
        updateDeviceInfo()
        
        locationManager.requestWhenInUseAuthorization()
        
        Task {
            if serverManager.servers.isEmpty {
                print("🚀 Loading servers on init...")
                await serverManager.fetchServers(userLocation: nil)
            } else {
                print("✅ Using cached servers: \(serverManager.servers.count)")
            }
        }
        fetchIPAddresses()
    }
    
    private func setupBindings() {
        speedTestManager.$ping
            .assign(to: &$pingAmount)
        
        speedTestManager.$jitter
            .assign(to: &$jitterAmount)
        
        speedTestManager.$packetLoss
            .assign(to: &$lossAmount)
        
        speedTestManager.$isConnected
            .assign(to: &$isConnected)
        
        speedTestManager.$connectionType
            .sink { [weak self] connectionType in
                self?.isWifiSource = (connectionType == .wifi)
            }
            .store(in: &cancellables)
        
        speedTestManager.$providerName
            .assign(to: &$sourceName)
        
        // Bind download and upload speeds - and capture history
        speedTestManager.$downloadSpeed
            .sink { [weak self] newSpeed in
                guard let self = self else { return }
                self.downloadSpeed = newSpeed
                
                // Capture speed history during test
                if self.isTestingStarted && newSpeed > 0 {
                    let newIndex = self.downloadSpeedHistory.isEmpty ? 0 : (self.downloadSpeedHistory.last?.index ?? 0) + 1
                    self.downloadSpeedHistory.append(SpeedDataPoint(index: newIndex, speed: newSpeed))
                    
                    // Limit to reasonable number of data points
                    if self.downloadSpeedHistory.count > 50 {
                        self.downloadSpeedHistory.removeFirst()
                        // Reindex
                        self.downloadSpeedHistory = self.downloadSpeedHistory.enumerated().map { index, point in
                            SpeedDataPoint(index: index, speed: point.speed)
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        speedTestManager.$uploadSpeed
            .sink { [weak self] newSpeed in
                guard let self = self else { return }
                self.uploadSpeed = newSpeed
                
                // Capture speed history during test
                if self.isTestingStarted && newSpeed > 0 {
                    let newIndex = self.uploadSpeedHistory.isEmpty ? 0 : (self.uploadSpeedHistory.last?.index ?? 0) + 1
                    self.uploadSpeedHistory.append(SpeedDataPoint(index: newIndex, speed: newSpeed))
                    
                    // Limit to reasonable number of data points
                    if self.uploadSpeedHistory.count > 50 {
                        self.uploadSpeedHistory.removeFirst()
                        // Reindex
                        self.uploadSpeedHistory = self.uploadSpeedHistory.enumerated().map { index, point in
                            SpeedDataPoint(index: index, speed: point.speed)
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        serverManager.$selectedServer
            .sink { [weak self] server in
                self?.updateServerInfo(server)
            }
            .store(in: &cancellables)
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.delegate = self
    }
    
    private func updateConnectionInfo() {
        isConnected = speedTestManager.isConnected
        isWifiSource = speedTestManager.connectionType == .wifi
        sourceName = speedTestManager.providerName
    }
    
    private func updateDeviceInfo() {
        phoneName = speedTestManager.getDeviceName()
    }
    
    private func fetchIPAddresses() {
        // Get internal IP
        internalIP = getInternalIP() ?? "N/A"
        
        // Get external IP
        Task {
            externalIP = await getExternalIP() ?? "N/A"
        }
    }
    
    private func getInternalIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" || name == "pdp_ip0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr,
                                  socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                                  &hostname,
                                  socklen_t(hostname.count),
                                  nil,
                                  socklen_t(0),
                                  NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
    
    private func getExternalIP() async -> String? {
        guard let url = URL(string: "https://api.ipify.org?format=text") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Failed to fetch external IP: \(error)")
            return nil
        }
    }
    
    private func updateServerInfo(_ server: ServerModel?) {
        guard let server = server else {
            serverName = "No server selected"
            serverLocationName = "Tap to select"
            print("⚠️ No server selected")
            return
        }
        
        serverName = server.provider
        serverLocationName = "\(server.city)"
        print("📍 Server updated: \(server.name) in \(server.city)")
    }
    
    func loadServers() {
        Task {
            await serverManager.fetchServers(userLocation: currentLocation)
        }
    }
    
    func startTest() {
        // Check internet connection first
        guard isConnected else {
            showErrorAlert = true
            return
        }
        
        guard let server = serverManager.selectedServer else {
            speedState = .error(message: "No server selected. Please select a server first.")
            return
        }
        
        // Reset values
        speed = 0
        pingAmount = 0
        jitterAmount = 0
        lossAmount = 0
        downloadSpeed = 0
        uploadSpeed = 0
        downloadSpeedHistory = []
        uploadSpeedHistory = []
        isTestingStarted = false
        
        speedState = .connecting
        
        Task {
            await performSpeedTest(server: server)
        }
    }
    
    private func performSpeedTest(server: ServerModel) async {
        await speedTestManager.performSpeedTest(server: server) { [weak self] state in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.speedState = state
                
                switch state {
                case .idle:
                    self.isTestingStarted = false
                    
                case .connecting:
                    self.isTestingStarted = false
                    
                case .testing(let currentSpeed):
                    self.isTestingStarted = true
                    self.speed = currentSpeed
                    
                case .complete(let finalSpeed):
                    self.speed = finalSpeed
                    self.isTestingStarted = false
                    
                    // Create test results with captured history
                    self.createTestResults()
                    
                    // Navigate to results
                    self.navigateToResults()
                    
                case .error(let message):
                    self.isTestingStarted = false
                    print("Test error: \(message)")
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func createTestResults() {
        testResults = TestResults(
            downloadSpeed: downloadSpeed,
            uploadSpeed: uploadSpeed,
            downloadHistory: downloadSpeedHistory,
            uploadHistory: uploadSpeedHistory,
            ping: pingAmount,
            jitter: jitterAmount,
            packetLoss: lossAmount,
            serverName: serverName,
            serverLocation: serverLocationName,
            connectionType: isWifiSource ? "Wi-Fi" : "Cellular",
            providerName: sourceName,
            internalIP: internalIP,
            externalIP: externalIP,
            testDate: Date()
        )
    }
    
    private func navigateToResults() {
        guard let results = testResults else { return }
        
        let resultView = ResultView(testResults: results)
        NavigationManager.shared.push(resultView)
    }
    
    func refreshConnectionStatus() {
        updateConnectionInfo()
    }
    
    func resetTest() {
        speedState = .idle
        speed = 0
        pingAmount = 0
        jitterAmount = 0
        lossAmount = 0
        downloadSpeed = 0
        uploadSpeed = 0
        downloadSpeedHistory = []
        uploadSpeedHistory = []
        isTestingStarted = false
    }
}

// MARK: - CLLocationManagerDelegate
extension TestViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        
        Task {
            await serverManager.fetchServers(userLocation: location)
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            Task {
                await serverManager.fetchServers(userLocation: nil)
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        
        Task {
            await serverManager.fetchServers(userLocation: nil)
        }
    }
}
