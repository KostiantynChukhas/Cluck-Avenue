import UIKit
import FirebaseCore
import SwiftUI
import FirebaseRemoteConfig

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let store = HenHavenDataManager()
    @StateObject private var attributionService = Services.shared.attributionService
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        FirebaseApp.configure()
        
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
    @State private var isRemoteConfigLoaded = false
    
    var body: some View {
        Group {
            if isRemoteConfigLoaded {
                if RemoteConfigService.shared.enableWView {
                    WebViewScreen(url: RemoteConfigService.shared.url)
                } else {
                    if data.hasCompletedOnboarding {
                        HenHavenTabView()
                    } else {
                        HenHavenOnboardingView()
                    }
                }
               
            } else {
                // Show a loading view while fetching remote config
                ProgressView("Loading...")
            }
        }
        .task {
            await fetchRemoteConfig()
        }
    }
    
    private func fetchRemoteConfig() async {
        let remoteConfigInstance = RemoteConfig.remoteConfig()
        let remoteConfigSettings = RemoteConfigSettings()
        remoteConfigSettings.minimumFetchInterval = 0
        remoteConfigInstance.configSettings = remoteConfigSettings
        remoteConfigInstance.setDefaults(fromPlist: "RemoteConfigDefaults")
        
        do {
            try await remoteConfigInstance.fetch()
            try await remoteConfigInstance.activate()
            
            // Обрабатываем значения Remote Config
            processRemoteConfigValues(remoteConfigInstance)
        } catch {
            print("Failed to fetch remote config:")
            print("Error: \(error.localizedDescription)")
        }
        
        isRemoteConfigLoaded = true
    }
    
    private func processRemoteConfigValues(_ remoteConfig: RemoteConfig) {
        let isEnabled = remoteConfig.configValue(forKey: "enableWView").boolValue
        let urlString = remoteConfig.configValue(forKey: "url").stringValue
        
        // Обновляем значения в сервисе
        RemoteConfigService.shared.updateValues(enableWView: isEnabled, url: urlString)
    }
}
