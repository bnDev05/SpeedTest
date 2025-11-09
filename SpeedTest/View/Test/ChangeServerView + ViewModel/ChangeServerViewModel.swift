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
        name: "Default Server",
        host: "speed.cloudflare.com",
        provider: "Cloudflare",
        city: "Global",
        country: "Worldwide",
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
        
        // Get current selected server
        self.selectedServer = serverManager.selectedServer ?? ServerModel(
            id: UUID(),
            name: "Default Server",
            host: "speed.cloudflare.com",
            provider: "Cloudflare",
            city: "Global",
            country: "Worldwide",
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
        
        setupBindings()
        setupLocationManager()
        loadServers()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind servers from server manager
        serverManager.$servers
            .assign(to: &$servers)
        
        // Filter servers based on search text
        $searchText
            .combineLatest($servers)
            .map { searchText, servers in
                self.filterServers(query: searchText, servers: servers)
            }
            .assign(to: &$filteredServers)
        
        // Update loading state
        serverManager.$isLoading
            .assign(to: &$isLoading)
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.delegate = self
        
        // Request location for distance calculation
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Server Management
    private func loadServers() {
        Task {
            await serverManager.fetchServers()
            
            // If no servers loaded, use defaults
            if servers.isEmpty {
                await MainActor.run {
                    servers = getDefaultServers()
                }
            }
            
            // Calculate distances if location available
            if let location = userLocation {
                updateServerDistances(location: location)
            }
        }
    }
    
    private func getDefaultServers() -> [ServerModel] {
        return [
            ServerModel(
                id: UUID(),
                name: "Cloudflare",
                host: "speed.cloudflare.com",
                provider: "Cloudflare Inc.",
                city: "Global",
                country: "Worldwide",
                countryCode: "WW",
                latitude: 0,
                longitude: 0,
                distanceKm: 0,
                pingMs: nil,
                isDefault: true,
                lastChecked: Date(),
                status: .active,
                supportedProtocols: ["HTTPS"],
                bandwidthLimits: nil
            ),
            ServerModel(
                id: UUID(),
                name: "Fast.com",
                host: "fast.com",
                provider: "Netflix",
                city: "Global",
                country: "Worldwide",
                countryCode: "WW",
                latitude: 0,
                longitude: 0,
                distanceKm: 0,
                pingMs: nil,
                isDefault: false,
                lastChecked: Date(),
                status: .active,
                supportedProtocols: ["HTTPS"],
                bandwidthLimits: nil
            ),
            ServerModel(
                id: UUID(),
                name: "Speedtest",
                host: "speedtest.net",
                provider: "Ookla",
                city: "Global",
                country: "Worldwide",
                countryCode: "WW",
                latitude: 0,
                longitude: 0,
                distanceKm: 0,
                pingMs: nil,
                isDefault: false,
                lastChecked: Date(),
                status: .active,
                supportedProtocols: ["HTTPS"],
                bandwidthLimits: nil
            )
        ]
    }
    
    private func filterServers(query: String, servers: [ServerModel]) -> [ServerModel] {
        guard !query.isEmpty else {
            return servers.sorted { $0.distanceKm < $1.distanceKm }
        }
        
        let filtered = servers.filter { server in
            server.name.localizedCaseInsensitiveContains(query) ||
            server.city.localizedCaseInsensitiveContains(query) ||
            server.country.localizedCaseInsensitiveContains(query) ||
            server.provider.localizedCaseInsensitiveContains(query)
        }
        
        return filtered.sorted { $0.distanceKm < $1.distanceKm }
    }
    
    // MARK: - Server Selection
    func selectServer(_ server: ServerModel) {
        selectedServer = server
        serverManager.selectServer(server)
    }
    
    func selectAutomatically() {
        guard let location = userLocation else {
            // If no location, select first available server
            if let firstServer = servers.first {
                selectServer(firstServer)
            }
            return
        }
        
        // Find closest server
        let sortedByDistance = servers.sorted { $0.distanceKm < $1.distanceKm }
        if let closestServer = sortedByDistance.first {
            selectServer(closestServer)
        }
    }
    
    // MARK: - Distance Calculation
    private func updateServerDistances(location: CLLocation) {
        let userCoordinate = (
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        servers = servers.map { server in
            var updatedServer = server
            let serverLocation = CLLocation(
                latitude: server.latitude,
                longitude: server.longitude
            )
            let distance = location.distance(from: serverLocation) / 1000 // Convert to km
            updatedServer = ServerModel(
                id: server.id,
                name: server.name,
                host: server.host,
                provider: server.provider,
                city: server.city,
                country: server.country,
                countryCode: server.countryCode,
                latitude: server.latitude,
                longitude: server.longitude,
                distanceKm: distance,
                pingMs: server.pingMs,
                isDefault: server.isDefault,
                lastChecked: server.lastChecked,
                status: server.status,
                supportedProtocols: server.supportedProtocols,
                bandwidthLimits: server.bandwidthLimits
            )
            return updatedServer
        }
    }
    
    // MARK: - Ping Test
    func testServerPing(_ server: ServerModel) async -> Int? {
        let speedTestManager = SpeedTestManager.shared
        
        // Perform a quick ping test
        if let pingTime = await speedTestManager.measurePing(host: server.host) {
            return Int(pingTime)
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    func refreshServers() {
        Task {
            await loadServers()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ChangeServerViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        userLocation = location
        updateServerDistances(location: location)
        
        // Stop updating after getting location
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
