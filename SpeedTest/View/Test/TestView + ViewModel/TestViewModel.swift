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
    
    @Published var isTestingStarter: Bool = true
    @Published var downloadSpeed: Double = 0.0
    @Published var uploadSpeed: Double = 0.0
    
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
            return
        }
        
        serverName = server.provider
        serverLocationName = "\(server.city)"
    }
    
    func loadServers() {
        Task {
            await serverManager.fetchServers(userLocation: currentLocation)
        }
    }
    
    func startTest() {
        guard isConnected else {
            speedState = .error(message: "No internet connection")
            return
        }
        
        guard let server = serverManager.selectedServer else {
            speedState = .error(message: "No server selected. Please select a server first.")
            return
        }
        
        speed = 0
        pingAmount = 0
        jitterAmount = 0
        lossAmount = 0
        
        speedState = .connecting
        
        Task {
            await performSpeedTest(server: server)
        }
    }
    
    private func performSpeedTest(server: ServerModel) async {
        await speedTestManager.performSpeedTest(server: server) { [weak self] state in
            Task { @MainActor in
                self?.speedState = state
                
                switch state {
                case .testing(let currentSpeed):
                    self?.speed = currentSpeed
                case .complete(let finalSpeed):
                    self?.speed = finalSpeed
                default:
                    break
                }
            }
        }
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
        print("Location error: \(error.localizedDescription)")
        
        Task {
            await serverManager.fetchServers(userLocation: nil)
        }
    }
}
