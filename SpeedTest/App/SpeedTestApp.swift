import SwiftUI
import CoreData
import FirebaseCore
import FirebaseCrashlytics
import Bugsnag
import BugsnagPerformance

@main
struct SpeedTestApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var quickActionManager = QuickActionManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showSubscription = false
    @AppStorage("CurrentAppIcon") private var currentAppIcon: CustomAppIcon = .defaultIcon
    
    init() {
        FirebaseApp.configure()
        Bugsnag.start()
        BugsnagPerformance.start()
    }
    
    var body: some Scene {
        WindowGroup {
                NavigationStack {
                    Group {
                        if subscriptionManager.isSubscribed {
                            TabView()
                        } else {
                            ContentView()
                        }
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(quickActionManager)
                    .onAppear {
                        updateQuickActions()
                        syncAppIcon()
                    }
                    .onChange(of: subscriptionManager.isSubscribed) { _ in
                        updateQuickActions()
                    }
                    .onChange(of: quickActionManager.quickAction) { action in
                        if action == .openSubscription {
                            showSubscription = true
                            quickActionManager.quickAction = nil
                        }
                    }
                    .navigationDestination(isPresented: $showSubscription) {
                        OnboardingView(step: 6)
                    }
                }
            }
    }
    
    private func updateQuickActions() {
        quickActionManager.updateQuickActions(hasActiveSubscription: subscriptionManager.isSubscribed)
    }

    private func syncAppIcon() {
        DispatchQueue.main.async {
            let currentIconName = UIApplication.shared.alternateIconName
            if currentIconName != currentAppIcon.displayName {
                AppIconManager.shared.setAppIcon(to: currentAppIcon, showAlert: false)
            }
        }
    }
}
