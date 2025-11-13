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
    
    // NEW: Track which speed to display
    @Published var isDownloadSpeed: Bool = true
    
    @Published var isWifiSource: Bool = true
    @Published var sourceName: String = "Unknown"
    @Published var phoneName: String = ""
    
    @Published var serverName: String = "Loading..."
    @Published var serverLocationName: String = "..."
    
    @Published var isTestingStarted: Bool = false
    @Published var downloadSpeed: Double = 0.0
    @Published var uploadSpeed: Double = 0.0
    
    @Published var showErrorAlert: Bool = false
    @Published var testResults: TestResults?
    
    @Published var downloadSpeedHistory: [SpeedDataPoint] = []
    @Published var uploadSpeedHistory: [SpeedDataPoint] = []
    
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
                await serverManager.fetchServers(userLocation: nil)
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
        
        // NEW: Track test phase to switch between download/upload
        speedTestManager.$currentTestPhase
            .sink { [weak self] phase in
                guard let self = self else { return }
                switch phase {
                case .download:
                    self.isDownloadSpeed = true
                case .upload:
                    self.isDownloadSpeed = false
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        speedTestManager.$downloadSpeed
            .sink { [weak self] newSpeed in
                guard let self = self else { return }
                self.downloadSpeed = newSpeed
                
                if self.isTestingStarted && newSpeed > 0 {
                    let newIndex = self.downloadSpeedHistory.isEmpty ? 0 : (self.downloadSpeedHistory.last?.index ?? 0) + 1
                    self.downloadSpeedHistory.append(SpeedDataPoint(index: newIndex, speed: newSpeed))
                    
                    if self.downloadSpeedHistory.count > 50 {
                        self.downloadSpeedHistory.removeFirst()
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
                
                if self.isTestingStarted && newSpeed > 0 {
                    let newIndex = self.uploadSpeedHistory.isEmpty ? 0 : (self.uploadSpeedHistory.last?.index ?? 0) + 1
                    self.uploadSpeedHistory.append(SpeedDataPoint(index: newIndex, speed: newSpeed))
                    
                    if self.uploadSpeedHistory.count > 50 {
                        self.uploadSpeedHistory.removeFirst()
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
    
    func startTest() {
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
        isDownloadSpeed = true // Start with download
        
        speedState = .connecting
        
        Task {
            await performSpeedTest(server: server)
        }
    }
    
    private func performSpeedTest(server: ServerModel) async {
        await speedTestManager.performSpeedTest(server: server) { [weak self] state, phase in
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
                    self.createTestResults()
                    self.navigateToResults()
                    
                case .error(let message):
                    self.isTestingStarted = false
                    print("Test error: \(message)")
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    // Keep all other existing methods...
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
        internalIP = getInternalIP() ?? "N/A"
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
            return nil
        }
    }
    
    private func updateServerInfo(_ server: ServerModel?) {
        guard let server = server else {
            serverName = "No server selected"
            serverLocationName = "Tap to select"
            return
        }
        
        serverName = server.provider
        serverLocationName = "\(server.city)"
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
        if let testResults {
            TestResultEntity.create(from: testResults)
        }
    }
    
    private func navigateToResults() {
        lossAmount = 0
        pingAmount = 0
        jitterAmount = 0
        guard let results = testResults else { return }
        let resultView = ResultView(testResults: results)
        NavigationManager.shared.push(resultView)
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
        isDownloadSpeed = true
    }
}

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
        Task {
            await serverManager.fetchServers(userLocation: nil)
        }
    }
}
