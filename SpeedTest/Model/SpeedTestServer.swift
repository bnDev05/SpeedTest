import Foundation
import CoreLocation

struct ServerModel: Identifiable, Codable {
    let id: UUID
    let name: String
    let host: String
    let provider: String
    let city: String
    let country: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let distanceKm: Double
    let pingMs: Double?
    let isDefault: Bool
    let lastChecked: Date?
    let status: ServerStatus
    let supportedProtocols: [String]
    let bandwidthLimits: BandwidthLimits?
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    enum ServerStatus: String, Codable {
        case active
        case offline
        case maintenance
    }
    
    struct BandwidthLimits: Codable {
        let downloadMbps: Double?
        let uploadMbps: Double?
    }
}
