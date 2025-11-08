
import SwiftUI
import UIKit

class NavigationManager: NSObject {
    
    static let shared = NavigationManager()
    
    func showIndicator<Content: View>(_ content: Content) {
        let hostingController = UIHostingController(rootView: content)
        hostingController.isModalInPresentation = true
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.view.backgroundColor = .clear
        NavigationManager.shared.topViewController?.present(hostingController, animated: true)
    }
    
    func hideIndicator(completion: @escaping() -> ()) {
        NavigationManager.shared.topViewController?.dismiss(animated: true) {
            completion()
        }
    }
    
    @objc func didTapBackground() {
        NavigationManager.shared.dismissDatePicker {}
    }
    
    func dismissDatePicker(completion: @escaping() -> ()) {
        NavigationManager.shared.topViewController?.dismiss(animated: true) {
            completion()
        }
    }
    
    func present<Content: View>(_ content: Content, isFullScreenCover: Bool = false, isCrossDissolve: Bool = false) {
        let hostingController = UIHostingController(rootView: content)
        hostingController.isModalInPresentation = true
        if isCrossDissolve {
            hostingController.modalTransitionStyle = .crossDissolve
            hostingController.view.backgroundColor = .clear
        }
        if isFullScreenCover {
            hostingController.modalPresentationStyle = .overFullScreen
        }
        NavigationManager.shared.topViewController?.present(hostingController, animated: true)
    }
    
//    func showRateView() {
//        let hostingController = UIHostingController(rootView: RateAppView())
//        hostingController.modalPresentationStyle = .overFullScreen
//        NavigationManager.shared.topViewController?.present(hostingController, animated: true)
//    }
    
    func push<Content: View>(_ content: Content) {
        let hostingController = UIHostingController(rootView: content)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    var topViewController: UIViewController? {
        var rootViewController: UIViewController? = rootViewController
        while rootViewController?.presentedViewController != nil {
            rootViewController = rootViewController?.presentedViewController
        }
        return rootViewController
    }
    
    var rootViewController: UIViewController? {
        return UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first?.rootViewController
    }
    
    var navigationController: UINavigationController? {
        return findNavigationController(viewController: rootViewController)
    }
    
    private func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        for childViewController in viewController.children {
            return findNavigationController(viewController: childViewController)
        }
        return nil
    }
    
    
}
