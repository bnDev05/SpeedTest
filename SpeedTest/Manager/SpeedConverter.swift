import Foundation

enum SpeedUnit: Int, CaseIterable {
    case mbitPerSec = 0  // Mbit/s
    case mbPerSec = 1    // MB/s
    case kbPerSec = 2    // KB/s
    
    var displayName: String {
        switch self {
        case .mbitPerSec: return "Mbit/s"
        case .mbPerSec: return "MB/s"
        case .kbPerSec: return "KB/s"
        }
    }
    
    // Convert from Mbit/s (base unit) to the selected unit
    func convertFromMbitPerSec(_ value: Double) -> Double {
        switch self {
        case .mbitPerSec:
            return value
        case .mbPerSec:
            return value / 8.0  // 1 MB/s = 8 Mbit/s
        case .kbPerSec:
            return value * 125.0  // 1 Mbit/s = 125 KB/s
        }
    }
}

enum DialScale: Int, CaseIterable {
    case scale1000 = 0
    case scale500 = 1
    case scale100 = 2
    
    var maxValue: Int {
        switch self {
        case .scale1000: return 1000
        case .scale500: return 500
        case .scale100: return 100
        }
    }
    
    var displayName: String {
        return "\(maxValue)"
    }
    
    // Get speed marks for the dial based on scale
    func getSpeedMarks() -> [(value: Int, angle: Double)] {
        switch self {
        case .scale1000:
            return [
                (value: 0, angle: 150.0),
                (value: 10, angle: 170.0),
                (value: 20, angle: 190.0),
                (value: 50, angle: 220.0),
                (value: 100, angle: 260.0),
                (value: 200, angle: 300.0),
                (value: 300, angle: 330.0),
                (value: 600, angle: 360.0),
                (value: 1000, angle: 390.0)
            ]
        case .scale500:
            return [
                (value: 0, angle: 150.0),
                (value: 10, angle: 175.0),
                (value: 20, angle: 200.0),
                (value: 50, angle: 235.0),
                (value: 100, angle: 280.0),
                (value: 200, angle: 325.0),
                (value: 300, angle: 360.0),
                (value: 600, angle: 390.0)
            ]
        case .scale100:
            return [
                (value: 0, angle: 150.0),
                (value: 1, angle: 165.0),
                (value: 5, angle: 195.0),
                (value: 10, angle: 225.0),
                (value: 20, angle: 265.0),
                (value: 30, angle: 295.0),
                (value: 50, angle: 335.0),
                (value: 75, angle: 365.0),
                (value: 100, angle: 390.0)
            ]
        }
    }
    
    // Calculate progress for needle position (0.0 to 1.0)
    func calculateProgress(for speed: Double) -> Double {
        let clampedSpeed = min(speed, Double(maxValue))
        
        switch self {
        case .scale1000:
            if clampedSpeed <= 0 { return 0 }
            else if clampedSpeed <= 10 { return clampedSpeed / 10 * 0.1 }
            else if clampedSpeed <= 50 { return 0.1 + (clampedSpeed - 10) / 40 * 0.2 }
            else if clampedSpeed <= 100 { return 0.3 + (clampedSpeed - 50) / 50 * 0.2 }
            else if clampedSpeed <= 300 { return 0.5 + (clampedSpeed - 100) / 200 * 0.25 }
            else if clampedSpeed <= 1000 { return 0.75 + (clampedSpeed - 300) / 700 * 0.25 }
            return 1.0
            
        case .scale500:
            if clampedSpeed <= 0 { return 0 }
            else if clampedSpeed <= 10 { return clampedSpeed / 10 * 0.12 }
            else if clampedSpeed <= 20 { return 0.12 + (clampedSpeed - 10) / 10 * 0.12 }
            else if clampedSpeed <= 50 { return 0.24 + (clampedSpeed - 20) / 30 * 0.18 }
            else if clampedSpeed <= 100 { return 0.42 + (clampedSpeed - 50) / 50 * 0.21 }
            else if clampedSpeed <= 200 { return 0.63 + (clampedSpeed - 100) / 100 * 0.21 }
            else if clampedSpeed <= 300 { return 0.84 + (clampedSpeed - 200) / 100 * 0.16 }
            return 1.0
            
        case .scale100:
            if clampedSpeed <= 0 { return 0 }
            else if clampedSpeed <= 1 { return clampedSpeed / 1 * 0.08 }
            else if clampedSpeed <= 5 { return 0.08 + (clampedSpeed - 1) / 4 * 0.15 }
            else if clampedSpeed <= 10 { return 0.23 + (clampedSpeed - 5) / 5 * 0.15 }
            else if clampedSpeed <= 20 { return 0.38 + (clampedSpeed - 10) / 10 * 0.17 }
            else if clampedSpeed <= 30 { return 0.55 + (clampedSpeed - 20) / 10 * 0.15 }
            else if clampedSpeed <= 50 { return 0.70 + (clampedSpeed - 30) / 20 * 0.17 }
            else if clampedSpeed <= 75 { return 0.87 + (clampedSpeed - 50) / 25 * 0.08 }
            else if clampedSpeed <= 100 { return 0.95 + (clampedSpeed - 75) / 25 * 0.05 }
            return 1.0
        }
    }
}

// Helper class to manage speed conversion and display
class SpeedConverter {
    static let shared = SpeedConverter()
    
    func convertSpeed(_ speedInMbit: Double, to unit: SpeedUnit) -> Double {
        return unit.convertFromMbitPerSec(speedInMbit)
    }
    
    func formatSpeed(_ speed: Double, unit: SpeedUnit, dialScale: DialScale) -> String {
        let convertedSpeed = convertSpeed(speed, to: unit)
        
        // Always show actual value in text, even if it exceeds dial scale
        if convertedSpeed >= 100 {
            return String(format: "%.2f", convertedSpeed)
        } else if convertedSpeed >= 10 {
            return String(format: "%.2f", convertedSpeed)
        } else {
            return String(format: "%.2f", convertedSpeed)
        }
    }
    
    // Get the speed value to use for dial position (clamped to max)
    func getDialSpeed(_ speedInMbit: Double, unit: SpeedUnit, dialScale: DialScale) -> Double {
        let convertedSpeed = convertSpeed(speedInMbit, to: unit)
        return min(convertedSpeed, Double(dialScale.maxValue))
    }
}
