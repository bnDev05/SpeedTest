import SwiftUI
import Combine

class QuickActionManager: ObservableObject {
    enum Action: String {
        case openSubscription = "BUNDLE.opensubscription"
    }

    @Published var quickAction: Action? = nil

    func handle(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = Action(rawValue: shortcutItem.type) else {
            return false
        }

        DispatchQueue.main.async {
            self.quickAction = action
        }
        return true
    }

    func configureQuickActions() {
        let subscriptionAction = UIApplicationShortcutItem(
            type: Action.openSubscription.rawValue,
            localizedTitle: "dont_delete".localized,
            localizedSubtitle: "try_it_off".localized,
            icon: UIApplicationShortcutIcon(systemImageName: "flame.fill"),
            userInfo: nil
        )

        UIApplication.shared.shortcutItems = [subscriptionAction]
    }
}

extension QuickActionManager {
    func updateQuickActions(hasActiveSubscription: Bool) {
        if hasActiveSubscription {
            UIApplication.shared.shortcutItems = []
        } else {
            configureQuickActions()
        }
    }
}
