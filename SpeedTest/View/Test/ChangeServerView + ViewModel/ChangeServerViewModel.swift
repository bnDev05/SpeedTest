import SwiftUI
import Combine

final class ChangeServerViewModel: ObservableObject {
    @Published var searchText: String = "" // here searchView's text goes
    @Published var servers: [ServerModel] = [
        ServerModel(
            id: UUID(),
            name: "ByFly",
            host: "speedtest.byfly.by",
            provider: "Beltelecom",
            city: "Minsk",
            country: "Belarus",
            countryCode: "BY",
            latitude: 53.9006,
            longitude: 27.5590,
            distanceKm: 3.0,
            pingMs: 12.4,
            isDefault: false,
            lastChecked: Date(),
            status: .active,
            supportedProtocols: ["HTTP", "HTTPS"],
            bandwidthLimits: ServerModel.BandwidthLimits(
                downloadMbps: nil,
                uploadMbps: nil
            )
        )
    ] // there we should actually have servers
    @Published var selectedServer: ServerModel = ServerModel(
        id: UUID(),
        name: "ByFly",
        host: "speedtest.byfly.by",
        provider: "Beltelecom",
        city: "Minsk",
        country: "Belarus",
        countryCode: "BY",
        latitude: 53.9006,
        longitude: 27.5590,
        distanceKm: 3.0,
        pingMs: 12.4,
        isDefault: false,
        lastChecked: Date(),
        status: .active,
        supportedProtocols: ["HTTP", "HTTPS"],
        bandwidthLimits: ServerModel.BandwidthLimits(
            downloadMbps: nil,
            uploadMbps: nil
        )
    ) // instead of that static ServerModel, we should set selected ServerModel (or passed from TestView)
    
    
}

