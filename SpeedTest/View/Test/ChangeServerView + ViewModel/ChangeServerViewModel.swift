import SwiftUI
import Combine
import CoreLocation

final class ChangeServerViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var servers: [ServerModel] = []
    @Published var filteredServers: [ServerModel] = []
    @Published var selectedServer: ServerModel = ServerModel(
        id: UUID(),
        name: "Loading...",
        host: "speedtest.net",
        provider: "Loading...",
        city: "...",
        country: "...",
        countryCode: "WW",
        latitude: 0,
        longitude: 0,
        distanceKm: 0,
        pingMs: nil,
        isDefault: true,
        lastChecked: nil,
        status: .active,
        supportedProtocols: ["HTTPS"],
        bandwidthLimits: nil
    )
    @Published var isLoading: Bool = false
    @Published var userLocation: CLLocation?
    
    // MARK: - Private Properties
    private let serverManager = ServerManager.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        // Update selected server from server manager if available
        if let currentServer = serverManager.selectedServer {
            self.selectedServer = currentServer
        }
        
        setupBindings()
        setupLocationManager()
        loadServersIfNeeded()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind servers from server manager
        serverManager.$servers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] servers in
                print("📡 Received \(servers.count) servers in ViewModel")
                self?.servers = servers
                self?.updateFilteredServers()
            }
            .store(in: &cancellables)
        
        // Filter servers based on search text
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                print("🔍 Searching for: '\(searchText)'")
                self?.updateFilteredServers()
            }
            .store(in: &cancellables)
        
        // Update loading state
        serverManager.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                print("⏳ Loading state: \(isLoading)")
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        // Update selected server when it changes
        serverManager.$selectedServer
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] server in
                print("✅ Selected server updated: \(server.name)")
                self?.selectedServer = server
            }
            .store(in: &cancellables)
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.delegate = self
        
        // Request location if authorized
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Server Management
    private func loadServersIfNeeded() {
        // Only fetch if we don't have servers yet
        if serverManager.servers.isEmpty {
            Task {
                await serverManager.fetchServers(userLocation: userLocation)
            }
        } else {
            // Use existing servers
            servers = serverManager.servers
            updateFilteredServers()
        }
    }
    
    private func updateFilteredServers() {
        if searchText.isEmpty {
            filteredServers = servers.sorted { $0.distanceKm < $1.distanceKm }
        } else {
            let filtered = servers.filter { server in
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.city.localizedCaseInsensitiveContains(searchText) ||
                server.country.localizedCaseInsensitiveContains(searchText) ||
                server.provider.localizedCaseInsensitiveContains(searchText)
            }
            filteredServers = filtered.sorted { $0.distanceKm < $1.distanceKm }
        }
    }
    
    // MARK: - Server Selection
    func selectServer(_ server: ServerModel) {
        selectedServer = server
        serverManager.selectServer(server)
    }
    
    func selectAutomatically() {
        // Select the closest server (first in sorted list)
        if let closestServer = filteredServers.first {
            selectServer(closestServer)
        } else if let firstServer = servers.first {
            selectServer(firstServer)
        }
    }
    
    // MARK: - Distance Calculation
    private func updateServerDistances(location: CLLocation) {
        serverManager.updateServerDistances(userLocation: location)
    }
    
    // MARK: - Ping Test
    func testServerPing(_ server: ServerModel) async -> Int? {
        let speedTestManager = SpeedTestManager.shared
        
        if let pingTime = await speedTestManager.measurePing(host: server.host) {
            return Int(pingTime)
        }
        
        return nil
    }
    
    // MARK: - Refresh
    func refreshServers() {
        Task {
            await serverManager.fetchServers(userLocation: userLocation)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ChangeServerViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        userLocation = location
        updateServerDistances(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            // Continue without location
            break
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
