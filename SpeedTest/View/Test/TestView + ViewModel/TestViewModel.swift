import SwiftUI
import Combine
import CoreLocation

final class TestViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
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
    
    @Published var serverName: String = "Selecting..."
    @Published var serverLocationName: String = "..."
    
    // MARK: - Private Properties
    private let speedTestManager = SpeedTestManager.shared
    private let serverManager = ServerManager.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupBindings()
        setupLocationManager()
        updateConnectionInfo()
        updateDeviceInfo()
        loadSelectedServer()
        
        // Request location permission for optimal server selection
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind speed test manager values
        speedTestManager.$ping
            .assign(to: &$pingAmount)
        
        speedTestManager.$jitter
            .assign(to: &$jitterAmount)
        
        speedTestManager.$packetLoss
            .assign(to: &$lossAmount)
        
        speedTestManager.$isConnected
            .assign(to: &$isConnected)
        
        // Bind connection type and provider
        speedTestManager.$connectionType
            .sink { [weak self] connectionType in
                self?.isWifiSource = (connectionType == .wifi)
            }
            .store(in: &cancellables)
        
        speedTestManager.$providerName
            .assign(to: &$sourceName)
        
        // Bind selected server info
        serverManager.$selectedServer
            .sink { [weak self] server in
                self?.updateServerInfo(server)
            }
            .store(in: &cancellables)
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.delegate = nil
    }
    
    // MARK: - Update Methods
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
            serverLocationName = "Please select a server"
            return
        }
        
        serverName = server.provider
        serverLocationName = "\(server.city), \(server.country)"
    }
    
    private func loadSelectedServer() {
        // Load previously selected server or find optimal one
        if serverManager.selectedServer == nil {
            Task {
                await selectOptimalServer()
            }
        }
    }
    
    // MARK: - Speed Test
    func startTest() {
        guard isConnected else {
            speedState = .error(message: "No internet connection")
            return
        }
        
        guard let server = serverManager.selectedServer else {
            speedState = .error(message: "No server selected")
            return
        }
        
        speedState = .connecting
        
        Task {
            await performSpeedTest(server: server)
        }
    }
    
    private func performSpeedTest(server: ServerModel) async {
        await speedTestManager.performSpeedTest(server: server) { [weak self] state in
            DispatchQueue.main.async {
                self?.speedState = state
                
                // Update speed value for UI
                if case .testing(let currentSpeed) = state {
                    self?.speed = currentSpeed
                } else if case .complete(let finalSpeed) = state {
                    self?.speed = finalSpeed
                }
            }
        }
    }
    
    // MARK: - Server Selection
    private func selectOptimalServer() async {
        // Try to get user location
        if let location = locationManager.location {
            let userLocation = (
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            if let optimalServer = speedTestManager.findOptimalServer(
                from: serverManager.servers,
                userLocation: userLocation
            ) {
                await MainActor.run {
                    serverManager.selectServer(optimalServer)
                }
            }
        } else {
            // Use first available server if location not available
            if let firstServer = serverManager.servers.first {
                await MainActor.run {
                    serverManager.selectServer(firstServer)
                }
            }
        }
    }
    
    // MARK: - Unit Conversion
    func convertSpeed(from mbps: Double, to unit: String) -> String {
        switch unit {
        case "Mbps":
            return String(format: "%.2f", mbps)
        case "Kbps":
            return String(format: "%.0f", mbps * 1000)
        case "MB/s":
            return String(format: "%.2f", mbps / 8)
        default:
            return String(format: "%.2f", mbps)
        }
    }
    
    // MARK: - Helper Methods
    func refreshConnectionStatus() {
        updateConnectionInfo()
    }
    
    func resetTest() {
        speedState = .idle
        speed = 0
        pingAmount = 0
        jitterAmount = 0
        lossAmount = 0
    }
}

// MARK: - CLLocationManagerDelegate (if needed)
extension TestViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let userLocation = (
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        // Update server distances
        serverManager.updateServerDistances(userLocation: userLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}
