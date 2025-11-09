import Foundation
import Network
import SystemConfiguration.CaptiveNetwork
import CoreTelephony
import UIKit
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
            // Try to get WiFi SSID
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
        // Reset values
        await MainActor.run {
            downloadSpeed = 0
            uploadSpeed = 0
            ping = 0
            jitter = 0
            packetLoss = 0
            pingResults = []
        }
        
        // Step 1: Ping Test
        await performPingTest(server: server, progress: progress)
        
        // Step 2: Download Test
        await performDownloadTest(server: server, progress: progress)
        
        // Step 3: Upload Test
        await performUploadTest(server: server, progress: progress)
        
        // Complete
        await MainActor.run {
            progress(.complete(speed: downloadSpeed))
        }
    }
    
    // MARK: - Ping Test
    private func performPingTest(server: ServerModel, progress: @escaping (SpeedTestState) -> Void) async {
        let pingCount = 10
        var results: [Double] = []
        
        for i in 0..<pingCount {
            if let pingTime = await measurePing(host: server.host) {
                results.append(pingTime)
                
                await MainActor.run {
                    let avgPing = results.reduce(0, +) / Double(results.count)
                    self.ping = Int(avgPing)
                    
                    // Calculate jitter
                    if results.count > 1 {
                        var jitterSum = 0.0
                        for j in 1..<results.count {
                            jitterSum += abs(results[j] - results[j-1])
                        }
                        self.jitter = Int(jitterSum / Double(results.count - 1))
                    }
                }
            } else {
                await MainActor.run {
                    self.packetLoss = Int(Double(pingCount - results.count) / Double(pingCount) * 100)
                }
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        await MainActor.run {
            pingResults = results
        }
    }
    
    func measurePing(host: String) async -> Double? {
        let startTime = Date()
        
        guard let url = URL(string: "https://\(host)") else { return nil }
        
        do {
            var request = URLRequest(url: url, timeoutInterval: 5)
            request.httpMethod = "HEAD"
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let pingTime = Date().timeIntervalSince(startTime) * 1000 // Convert to ms
            return pingTime
        } catch {
            return nil
        }
    }
    
    // MARK: - Download Test
    private func performDownloadTest(server: ServerModel, progress: @escaping (SpeedTestState) -> Void) async {
        // Test with multiple file sizes to get accurate measurement
        let testDuration: TimeInterval = 10 // 10 seconds test
        let startTime = Date()
        var totalBytesReceived: Int64 = 0
        
        // Use different file sizes for testing
        let testSizes = ["10MB", "20MB", "50MB"] // Adjust based on server
        
        for testSize in testSizes {
            guard Date().timeIntervalSince(startTime) < testDuration else { break }
            
            if let bytes = await downloadFile(from: server, size: testSize) {
                totalBytesReceived += bytes
                
                let elapsedTime = Date().timeIntervalSince(startTime)
                let speedMbps = (Double(totalBytesReceived) * 8) / (elapsedTime * 1_000_000)
                
                await MainActor.run {
                    self.downloadSpeed = speedMbps
                    progress(.testing(speed: speedMbps))
                }
            }
        }
    }
    
    private func downloadFile(from server: ServerModel, size: String) async -> Int64? {
        // In real implementation, use actual test URLs from the server
        // This is a simulation using a large file download
        guard let url = URL(string: "https://\(server.host)/download?size=\(size)") else {
            // Fallback to a known test file URL
            guard let fallbackURL = URL(string: "https://speed.cloudflare.com/__down?bytes=10485760") else {
                return nil
            }
            return await downloadFromURL(fallbackURL)
        }
        
        return await downloadFromURL(url)
    }
    
    private func downloadFromURL(_ url: URL) async -> Int64? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return Int64(data.count)
        } catch {
            print("Download error: \(error)")
            return nil
        }
    }
    
    // MARK: - Upload Test
    private func performUploadTest(server: ServerModel, progress: @escaping (SpeedTestState) -> Void) async {
        let testDuration: TimeInterval = 10
        let startTime = Date()
        var totalBytesUploaded: Int64 = 0
        
        // Generate test data
        let chunkSize = 1024 * 1024 // 1MB chunks
        let testData = Data(repeating: 0, count: chunkSize)
        
        while Date().timeIntervalSince(startTime) < testDuration {
            if let bytes = await uploadData(to: server, data: testData) {
                totalBytesUploaded += bytes
                
                let elapsedTime = Date().timeIntervalSince(startTime)
                let speedMbps = (Double(totalBytesUploaded) * 8) / (elapsedTime * 1_000_000)
                
                await MainActor.run {
                    self.uploadSpeed = speedMbps
                }
            } else {
                break
            }
        }
    }
    
    private func uploadData(to server: ServerModel, data: Data) async -> Int64? {
        guard let url = URL(string: "https://\(server.host)/upload") else {
            // Fallback URL
            guard let fallbackURL = URL(string: "https://speed.cloudflare.com/__up") else {
                return nil
            }
            return await uploadToURL(fallbackURL, data: data)
        }
        
        return await uploadToURL(url, data: data)
    }
    
    private func uploadToURL(_ url: URL, data: Data) async -> Int64? {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = data
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            return Int64(data.count)
        } catch {
            print("Upload error: \(error)")
            return nil
        }
    }
    
    // MARK: - Server Selection
    func findOptimalServer(from servers: [ServerModel], userLocation: (latitude: Double, longitude: Double)) -> ServerModel? {
        var serversWithDistance = servers.map { server -> (server: ServerModel, distance: Double) in
            let distance = calculateDistance(
                from: userLocation,
                to: (latitude: server.latitude, longitude: server.longitude)
            )
            return (server, distance)
        }
        
        serversWithDistance.sort { $0.distance < $1.distance }
        
        return serversWithDistance.first?.server
    }
    
    private func calculateDistance(from: (latitude: Double, longitude: Double), to: (latitude: Double, longitude: Double)) -> Double {
        let earthRadius = 6371.0 // km
        
        let lat1Rad = from.latitude * .pi / 180
        let lat2Rad = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    // MARK: - Device Info
    func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

// MARK: - Server Manager
final class ServerManager: ObservableObject {
    static let shared = ServerManager()
    
    @Published var servers: [ServerModel] = []
    @Published var selectedServer: ServerModel?
    @Published var isLoading = false
    
    private init() {
        loadDefaultServers()
    }
    
    private func loadDefaultServers() {
        // In production, fetch this from your backend or Speedtest.net API
        servers = [
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
                isDefault: true,
                lastChecked: nil,
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
                lastChecked: nil,
                status: .active,
                supportedProtocols: ["HTTPS"],
                bandwidthLimits: nil
            )
        ]
        
        selectedServer = servers.first
    }
    
    func fetchServers() async {
        await MainActor.run {
            isLoading = true
        }
        
        // In production, fetch from Speedtest.net API or your backend
        // Example: https://www.speedtest.net/api/js/servers
        
        await MainActor.run {
            isLoading = false
        }
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
    
    func updateServerDistances(userLocation: (latitude: Double, longitude: Double)) {
        servers = servers.map { server in
            var updatedServer = server
            let distance = SpeedTestManager.shared.findOptimalServer(
                from: [server],
                userLocation: userLocation
            )
            return updatedServer
        }
    }
}
