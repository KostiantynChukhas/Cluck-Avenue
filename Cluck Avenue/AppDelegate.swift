import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let store = HenHavenDataManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        let rootView = RootView()
            .environmentObject(store)
            .preferredColorScheme(.light)
        
        window.rootViewController = UIHostingController(rootView: rootView)
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}

// MARK: - Root View that responds to onboarding changes
struct RootView: View {
    @EnvironmentObject var data: HenHavenDataManager
    
    var body: some View {
        if data.hasCompletedOnboarding {
            HenHavenTabView()
        } else {
            HenHavenOnboardingView()
        }
    }
}
