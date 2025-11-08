
import SwiftUI

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        var rgb: UInt64 = 0
        let isValid = Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        guard isValid else {
            self = .white
            return
        }
        
        let length = hexSanitized.count
        switch length {
        case 6:
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
        case 8:
            let a = Double((rgb & 0xFF000000) >> 24) / 255.0
            let r = Double((rgb & 0x00FF0000) >> 16) / 255.0
            let g = Double((rgb & 0x0000FF00) >> 8) / 255.0
            let b = Double(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        default:
            self = .white
        }
    }
}
