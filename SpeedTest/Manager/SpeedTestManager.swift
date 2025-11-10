import Foundation
import Network
import SystemConfiguration.CaptiveNetwork
import CoreTelephony
import UIKit
import CoreLocation
import Combine

// MARK: - Speed Test Manager
final class SpeedTestManager: ObservableObject {
    static let shared = SpeedTestManager()
    
    @Published var downloadSpeed: Double = 0 // Mbps
    @Published var uploadSpeed: Double = 0 // Mbps
    @Published var ping: Int = 0 // ms
    @Published var jitter: Int = 0 // ms
    @Published var packetLoss: Int = 0 // percentage
    @Published var isConnected: Bool = false
    @Published var connectionType: ConnectionType = .wifi
    @Published var providerName: String = "Unknown"
    @Published var currentServer: ServerModel?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var pingResults: [Double] = []
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        startMonitoring()
        detectConnectionType()
        detectProvider()
    }
    
    // MARK: - Network Monitoring
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.detectConnectionType()
                self?.detectProvider()
            }
        }
        monitor.start(queue: queue)
    }
    
    private func detectConnectionType() {
        let path = monitor.currentPath
        
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    private func detectProvider() {
        if connectionType == .cellular {
            let networkInfo = CTTelephonyNetworkInfo()
            if let carrier = networkInfo.serviceSubscriberCellularProviders?.values.first {
                providerName = carrier.carrierName ?? "Unknown Carrier"
            }
        } else if connectionType == .wifi {
            if let ssid = getWiFiSSID() {
                providerName = ssid
            } else {
                providerName = "Wi-Fi Network"
            }
        }
    }
    
    private func getWiFiSSID() -> String? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        for interface in interfaces {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                  let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                continue
            }
            return ssid
        }
        return nil
    }
    
    // MARK: - Speed Test Functions
    func performSpeedTest(server: ServerModel, progress: @escaping (SpeedTestState) -> Void) async {
        await MainActor.run {
            downloadSpeed = 0
            uploadSpeed = 0
            ping = 0
            jitter = 0
            packetLoss = 0
            pingResults = []
            currentServer = server
        }
        
        // Step 1: Ping Test
        await performPingTest(server: server, progress: progress)
        
        // Step 2: Download Test
        await performDownloadTest(server: server, progress: progress)
        
        // Step 3: Upload Test
        await performUploadTest(server: server, progress: progress)
        
        // Complete
        await MainActor.run {
            progress(.complete(speed: max(downloadSpeed, uploadSpeed)))
        }
    }
    
    // MARK: - Ping Test
    private func performPingTest(server: ServerModel, progress: @escaping (SpeedTestState) -> Void) async {
        let pingCount = 10
        var results: [Double] = []
        
        for _ in 0..<pingCount {
            if let pingTime = await measurePing(host: server.host) {
                results.append(pingTime)
                
                await MainActor.run {
                    let avgPing = results.reduce(0, +) / Double(results.count)
                    self.ping = Int(avgPing)
                    
                    if results.count > 1 {
                        var jitterSum = 0.0
                        for j in 1..<results.count {
                            jitterSum += abs(results[j] - results[j-1])
                        }
                        self.jitter = Int(jitterSum / Double(results.count - 1))
                    }
                }
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        await MainActor.run {
            pingResults = results
            let lossCount = pingCount - results.count
            self.packetLoss = Int(Double(lossCount) / Double(pingCount) * 100)
        }
    }
    
    func measurePing(host: String) async -> Double? {
        let startTime = Date()
        
        // Clean host - remove protocol if present
        var cleanHost = host.replacingOccurrences(of: "http://", with: "")
        cleanHost = cleanHost.replacingOccurrences(of: "https://", with: "")
        cleanHost = cleanHost.components(separatedBy: "/").first ?? cleanHost
        
        guard let url = URL(string: "https://\(cleanHost)") else { return nil }
        
        do {
            var request = URLRequest(url: url, timeoutInterval: 5)
            request.httpMethod = "HEAD"
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            let pingTime = Date().timeIntervalSince(startTime) * 1000
            return pingTime
        } catch {
            return nil
        }
    }
    
    // MARK: - Download Test
    private func performDownloadTest(server: ServerModel, progress: @escaping (SpeedTestState) -> Void) async {
        let testDuration: TimeInterval = 10
        let startTime = Date()
        var totalBytesReceived: Int64 = 0
        var testCount = 0
        
        // Use multiple concurrent downloads for accurate measurement
        await withTaskGroup(of: Int64?.self) { group in
            while Date().timeIntervalSince(startTime) < testDuration {
                group.addTask {
                    await self.downloadChunk(from: server)
                }
                
                testCount += 1
                if testCount >= 3 { // Limit concurrent downloads
                    if let bytes = await group.next() {
                        if let actualBytes = bytes {
                            totalBytesReceived += actualBytes
                            
                            let elapsedTime = Date().timeIntervalSince(startTime)
                            if elapsedTime > 0 {
                                let speedMbps = (Double(totalBytesReceived) * 8) / (elapsedTime * 1_000_000)
                                
                                await MainActor.run {
                                    self.downloadSpeed = speedMbps
                                    progress(.testing(speed: speedMbps))
                                }
                            }
                        }
                    }
                }
                
                if Date().timeIntervalSince(startTime) >= testDuration {
                    break
                }
            }
            
            // Collect remaining results
            for await bytes in group {
                if let actualBytes = bytes {
                    totalBytesReceived += actualBytes
                }
            }
        }
        
        let finalElapsedTime = Date().timeIntervalSince(startTime)
        if finalElapsedTime > 0 {
            let finalSpeedMbps = (Double(totalBytesReceived) * 8) / (finalElapsedTime * 1_000_000)
            await MainActor.run {
                self.downloadSpeed = finalSpeedMbps
            }
        }
    }
    
    private func downloadChunk(from server: ServerModel) async -> Int64? {
        // Generate random test file URL from server
        let sizes = [1048576, 2097152, 5242880] // 1MB, 2MB, 5MB
        let randomSize = sizes.randomElement() ?? 1048576
        
        var cleanHost = server.host.replacingOccurrences(of: "http://", with: "")
        cleanHost = cleanHost.replacingOccurrences(of: "https://", with: "")
        cleanHost = cleanHost.components(separatedBy: "/").first ?? cleanHost
        
        // Try server-specific download endpoint
        let downloadURLString = "https://\(cleanHost)/download?nocache=\(UUID().uuidString)&size=\(randomSize)"
        
        guard let url = URL(string: downloadURLString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return Int64(data.count)
        } catch {
            return nil
        }
    }
    
    // MARK: - Upload Test
    private func performUploadTest(server: ServerModel, progress: @escaping (SpeedTestState) -> Void) async {
        let testDuration: TimeInterval = 10
        let startTime = Date()
        var totalBytesUploaded: Int64 = 0
        
        let chunkSize = 1024 * 1024 // 1MB chunks
        
        while Date().timeIntervalSince(startTime) < testDuration {
            let testData = Data(count: chunkSize)
            
            if let bytes = await uploadChunk(to: server, data: testData) {
                totalBytesUploaded += bytes
                
                let elapsedTime = Date().timeIntervalSince(startTime)
                if elapsedTime > 0 {
                    let speedMbps = (Double(totalBytesUploaded) * 8) / (elapsedTime * 1_000_000)
                    
                    await MainActor.run {
                        self.uploadSpeed = speedMbps
                    }
                }
            } else {
                break
            }
        }
    }
    
    private func uploadChunk(to server: ServerModel, data: Data) async -> Int64? {
        var cleanHost = server.host.replacingOccurrences(of: "http://", with: "")
        cleanHost = cleanHost.replacingOccurrences(of: "https://", with: "")
        cleanHost = cleanHost.components(separatedBy: "/").first ?? cleanHost
        
        let uploadURLString = "https://\(cleanHost)/upload?nocache=\(UUID().uuidString)"
        guard let url = URL(string: uploadURLString) else { return nil }
        
        do {
            var request = URLRequest(url: url, timeoutInterval: 30)
            request.httpMethod = "POST"
            request.httpBody = data
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            return Int64(data.count)
        } catch {
            return nil
        }
    }
    
    // MARK: - Helper Methods
    func getDeviceName() -> String {
        return UIDevice.current.name
    }
}

// MARK: - Server Manager
final class ServerManager: ObservableObject {
    static let shared = ServerManager()
    
    @Published var servers: [ServerModel] = []
    @Published var selectedServer: ServerModel?
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Fetch Servers from Speedtest.net API
    func fetchServers(userLocation: CLLocation? = nil) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Fetch servers from Speedtest.net
            let fetchedServers = try await fetchSpeedtestServers(userLocation: userLocation)
            
            await MainActor.run {
                self.servers = fetchedServers
                
                // Auto-select closest server if none selected
                if self.selectedServer == nil, let firstServer = fetchedServers.first {
                    self.selectedServer = firstServer
                }
                
                isLoading = false
            }
        } catch {
            print("Error fetching servers: \(error)")
            
            // Fallback to default servers
            await MainActor.run {
                self.servers = getDefaultServers()
                if self.selectedServer == nil {
                    self.selectedServer = self.servers.first
                }
                isLoading = false
            }
        }
    }
    
    private func fetchSpeedtestServers(userLocation: CLLocation?) async throws -> [ServerModel] {
        // Speedtest.net server API
        let urlString = "https://www.speedtest.net/api/js/servers?engine=js&limit=50"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let serverResponse = try decoder.decode([SpeedtestServerResponse].self, from: data)
        
        // Convert to ServerModel
        var servers = serverResponse.map { response -> ServerModel in
            let location = userLocation ?? CLLocation(latitude: 0, longitude: 0)
            let serverLocation = CLLocation(latitude: response.lat, longitude: response.lon)
            let distance = location.distance(from: serverLocation) / 1000 // km
            
            return ServerModel(
                id: UUID(),
                name: response.sponsor,
                host: response.host,
                provider: response.sponsor,
                city: response.name,
                country: response.country,
                countryCode: response.cc,
                latitude: response.lat,
                longitude: response.lon,
                distanceKm: distance,
                pingMs: nil,
                isDefault: false,
                lastChecked: Date(),
                status: .active,
                supportedProtocols: ["HTTPS"],
                bandwidthLimits: nil
            )
        }
        
        // Sort by distance
        servers.sort { $0.distanceKm < $1.distanceKm }
        
        return servers
    }
    
    private func getDefaultServers() -> [ServerModel] {
        return [
            ServerModel(
                id: UUID(),
                name: "Speedtest by Ookla",
                host: "speedtest.net",
                provider: "Ookla",
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
                name: "Cloudflare",
                host: "speed.cloudflare.com",
                provider: "Cloudflare",
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
    
    func selectServer(_ server: ServerModel) {
        selectedServer = server
        UserDefaults.standard.set(server.id.uuidString, forKey: "selectedServerID")
    }
    
    func searchServers(query: String) -> [ServerModel] {
        guard !query.isEmpty else { return servers }
        
        return servers.filter { server in
            server.name.localizedCaseInsensitiveContains(query) ||
            server.city.localizedCaseInsensitiveContains(query) ||
            server.country.localizedCaseInsensitiveContains(query) ||
            server.provider.localizedCaseInsensitiveContains(query)
        }
    }
    
    func updateServerDistances(userLocation: CLLocation) {
        servers = servers.map { server in
            let serverLocation = CLLocation(latitude: server.latitude, longitude: server.longitude)
            let distance = userLocation.distance(from: serverLocation) / 1000
            
            return ServerModel(
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
        }
        
        // Re-sort by distance
        servers.sort { $0.distanceKm < $1.distanceKm }
    }
}

// MARK: - Speedtest API Response Models
// MARK: - Speedtest API Response Models
struct SpeedtestServerResponse: Codable {
    let url: String
    let lat: Double
    let lon: Double
    let name: String
    let country: String
    let cc: String
    let sponsor: String
    let id: String
    let host: String
    let url2: String?
    
    enum CodingKeys: String, CodingKey {
        case url, lat, lon, name, country, cc, sponsor, id, host
        case url2 = "url2"
    }
    
    // Custom decoder to handle both String and Double for lat/lon
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        url = try container.decode(String.self, forKey: .url)
        name = try container.decode(String.self, forKey: .name)
        country = try container.decode(String.self, forKey: .country)
        cc = try container.decode(String.self, forKey: .cc)
        sponsor = try container.decode(String.self, forKey: .sponsor)
        id = try container.decode(String.self, forKey: .id)
        host = try container.decode(String.self, forKey: .host)
        url2 = try? container.decode(String.self, forKey: .url2)
        
        // Handle lat - can be String or Double
        if let latDouble = try? container.decode(Double.self, forKey: .lat) {
            lat = latDouble
        } else if let latString = try? container.decode(String.self, forKey: .lat),
                  let latDouble = Double(latString) {
            lat = latDouble
        } else {
            lat = 0.0
        }
        
        // Handle lon - can be String or Double
        if let lonDouble = try? container.decode(Double.self, forKey: .lon) {
            lon = lonDouble
        } else if let lonString = try? container.decode(String.self, forKey: .lon),
                  let lonDouble = Double(lonString) {
            lon = lonDouble
        } else {
            lon = 0.0
        }
    }
}
