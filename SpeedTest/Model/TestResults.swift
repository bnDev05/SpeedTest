import SwiftUI

struct TestResults {
    let downloadSpeed: Double
    let uploadSpeed: Double
    let downloadHistory: [SpeedDataPoint]
    let uploadHistory: [SpeedDataPoint]
    let ping: Int
    let jitter: Int
    let packetLoss: Int
    let serverName: String
    let serverLocation: String
    let connectionType: String
    let providerName: String
    let internalIP: String
    let externalIP: String
    let testDate: Date
    
    var bandwidth: Double {
        return (downloadSpeed + uploadSpeed) / 2
    }
    
    var byAverage: Double {
        return 9.2 // This should be calculated based on historical data or global average
    }
    
    var watchVideosRating: Int {
        if downloadSpeed >= 25 { return 5 }
        else if downloadSpeed >= 15 { return 4 }
        else if downloadSpeed >= 10 { return 3 }
        else if downloadSpeed >= 5 { return 2 }
        else { return 1 }
    }
    
    var playGamesRating: Int {
        if ping < 30 && downloadSpeed >= 20 { return 5 }
        else if ping < 50 && downloadSpeed >= 15 { return 4 }
        else if ping < 80 && downloadSpeed >= 10 { return 3 }
        else if ping < 100 { return 2 }
        else { return 1 }
    }
    
    var uploadPhotosRating: Int {
        if uploadSpeed >= 10 { return 5 }
        else if uploadSpeed >= 7 { return 4 }
        else if uploadSpeed >= 5 { return 3 }
        else if uploadSpeed >= 3 { return 2 }
        else { return 1 }
    }
}

