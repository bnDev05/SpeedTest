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
    
    // Store speed history for charts
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
        
        // Bind download and upload speeds
        speedTestManager.$downloadSpeed
            .assign(to: &$downloadSpeed)
        
        speedTestManager.$uploadSpeed
            .assign(to: &$uploadSpeed)
        
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
    
    private func updateServerInfo(_ server: ServerModel?) {
        guard let server = server else {
            serverName = "No server selected"
            serverLocationName = "Tap to select"
            print("⚠️ No server selected")
            return
        }
        
        serverName = server.provider
        serverLocationName = "\(server.city), \(server.country)"
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
