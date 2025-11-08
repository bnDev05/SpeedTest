import UIKit
import SwiftUI


enum CustomAppIcon: String, CaseIterable, Identifiable, Codable {
    case defaultIcon = "appIcon0"
    case altIcon     = "appIcon1"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultIcon: return "Default"
        case .altIcon:     return "Alternate"
        }
    }


    var iconName: String? {
        switch self {
        case .defaultIcon: return nil
        case .altIcon:     return "appIcon1"
        }
    }

    var iconNameForSystem: String? { iconName }
}

final class AppIconManager {
    static let shared = AppIconManager()
    private init() {}

    func setAppIcon(to icon: CustomAppIcon, showAlert: Bool = true) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        if UIApplication.shared.alternateIconName != icon.iconName {
            UIApplication.shared.setAlternateIconName(icon.iconName) { error in
                if let error = error {
                    print("❌ Failed to change icon: \(error.localizedDescription)")
                } else {
                    print("✅ App icon set to \(icon.iconName ?? "default")")
                }
            }
        }
    }
}
