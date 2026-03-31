import Foundation
import UIKit
import AppsFlyerLib

struct AttributionInfo {
    
    enum `Type` {
        case appsflyer
        case custom
    }
    
    let type: `Type`
    let value: String
    let attribution: [AnyHashable: Any]?
    let deepLinkParams: DeepLinkParameters?
    
    init(type: Type, value: String, attribution: [AnyHashable: Any]?, deepLinkParams: DeepLinkParameters? = nil) {
        self.type = type
        self.value = value
        self.attribution = attribution
        self.deepLinkParams = deepLinkParams
    }
}

struct AppsFlyerInit {
    let devKey: String
    let appleAppID: String
}

protocol AppsFlyerServiceProtocol {
    func setup(application: UIApplication,
               launchOptions: [UIApplication.LaunchOptionsKey : Any]?,
               appsFlyerInit: AppsFlyerInit,
               onFinish: ((AttributionInfo)->Void)?) -> String
    
    func applicationDidBecomeActive(_ application: UIApplication)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any])
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void)
}

class AppsFlyerService: NSObject, AppsFlyerServiceProtocol {
        
    private enum Status {
        case notStarted
        case started
        case done
        
        var nextStatus: Status {
            switch self {
            case .notStarted:
                return .started
            case .started:
                return .done
            case .done:
                return .done
            }
        }
    }
    
    private var status: Status = .notStarted
    private var attributionValue: String = ""
    private var attributionDict: [AnyHashable: Any]? = nil
    private var deepLinkParams: DeepLinkParameters? = nil
    private var deepLinkService: DeepLinkService = DeepLinkService()
    
    private var onFinish: ((AttributionInfo) -> Void)?

    func setup(application: UIApplication,
               launchOptions: [UIApplication.LaunchOptionsKey : Any]?,
               appsFlyerInit: AppsFlyerInit,
               onFinish: ((AttributionInfo) -> Void)?) -> String {
        self.onFinish = onFinish
        
        AppsFlyerLib.shared().appsFlyerDevKey = appsFlyerInit.devKey
        AppsFlyerLib.shared().appleAppID = appsFlyerInit.appleAppID
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().isDebug = true
        
        if let deepLink = UserDefaults.standard.string(forKey: "appsflyer_deep_link_key") {
            if let date = UserDefaults.standard.object(forKey: "appsflyer_deep_link_date_key") as? Date,
               Date().timeIntervalSince1970 - date.timeIntervalSince1970 > 86400 {
                onFinish?(AttributionInfo(type: .appsflyer, value: "", attribution: nil, deepLinkParams: nil))
            } else {
                // Пытаемся восстановить параметры из UserDefaults
                let params = loadDeepLinkParameters()
                onFinish?(AttributionInfo(type: .appsflyer, value: deepLink, attribution: nil, deepLinkParams: params))
            }
        } else {
            AppsFlyerLib.shared().deepLinkDelegate = self
        }
        
        AppsFlyerLib.shared().appInviteOneLinkID = "JsLM"
        
        return AppsFlyerLib.shared().getAppsFlyerUID()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerLib.shared().start()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        AppsFlyerLib.shared().handlePushNotification(userInfo)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) {
        AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
        AppsFlyerLib.shared().handleOpen(url, options: options)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppsFlyerLib.shared().handlePushNotification(userInfo)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: { (restorableObjects) in
            restorationHandler(restorableObjects as? [UIUserActivityRestoring])
        })
    }
    
    // MARK: - Private Methods
    
    private func saveDeepLinkParameters(_ params: DeepLinkParameters) {
        // Сохраняем параметры как отдельные значения
        UserDefaults.standard.set(params.deepLinkValue, forKey: "appsflyer_deep_link_value")
        UserDefaults.standard.set(params.afSub1, forKey: "appsflyer_af_sub1")
        UserDefaults.standard.set(params.afAdset, forKey: "appsflyer_af_adset")
        UserDefaults.standard.set(params.deepLinkSub1, forKey: "appsflyer_deep_link_sub1")
        UserDefaults.standard.set(params.pid, forKey: "appsflyer_pid")
        UserDefaults.standard.set(params.isDeferred, forKey: "appsflyer_is_deferred")
        
        print("💾 [AppsFlyerService] Deep link parameters saved")
    }
    
    private func loadDeepLinkParameters() -> DeepLinkParameters? {
        // Проверяем есть ли сохраненные параметры
        guard let deepLinkValue = UserDefaults.standard.string(forKey: "appsflyer_deep_link_value") else {
            print("📂 [AppsFlyerService] No saved deep link parameters found")
            return nil
        }
        
        let afSub1 = UserDefaults.standard.string(forKey: "appsflyer_af_sub1") ?? ""
        let afAdset = UserDefaults.standard.string(forKey: "appsflyer_af_adset") ?? ""
        let deepLinkSub1 = UserDefaults.standard.string(forKey: "appsflyer_deep_link_sub1") ?? ""
        let pid = UserDefaults.standard.string(forKey: "appsflyer_pid") ?? ""
        let isDeferred = UserDefaults.standard.bool(forKey: "appsflyer_is_deferred")
        
        print("📂 [AppsFlyerService] Deep link parameters loaded")
        
//        #if DEBUG
//        return DeepLinkParameters(
//            deepLinkValue: deepLinkValue,
//            afSub1: afSub1,
//            afAdset: afAdset,
//            deepLinkSub1: deepLinkSub1,
//            pid: pid,
//            isDeferred: isDeferred,
//            allParameters: [:]
//        )
//        #else
        // В релизе не можем создать объект без инициализатора
        return nil
//        #endif
    }
}

// MARK: - AppsFlyerLibDelegate

extension AppsFlyerService: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ installData: [AnyHashable: Any]) {
        print("📊 [AppsFlyer] onConversionDataSuccess called")
        print("📊 [AppsFlyer] Conversion Data:")
        for (key, value) in installData {
            print("📊 [AppsFlyer]   \(key): \(value)")
        }
        
        attributionDict = installData
        status = status.nextStatus
        checkStatus()
    }
    
    func onConversionDataFail(_ error: any Error) {
        print("❌ [AppsFlyer] onConversionDataFail: \(error.localizedDescription)")
        status = status.nextStatus
        checkStatus()
    }
}

// MARK: - DeepLinkDelegate

extension AppsFlyerService: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        print("🔗 [AppsFlyer] didResolveDeepLink called")
        print("🔗 [AppsFlyer] Status: \(result.status)")
        
//        #if DEBUG
//        // Для дебага выводим ВСЕ параметры
//        if let deepLink = result.deepLink {
//            print("🔗 [DEBUG] === ALL DEEP LINK PARAMETERS ===")
//            print("🔗 [DEBUG] DeepLink Value: \(deepLink.deeplinkValue ?? "nil")")
//            print("🔗 [DEBUG] Is Deferred: \(deepLink.isDeferred)")
//            print("🔗 [DEBUG] Click Event Dictionary:")
//            for (key, value) in deepLink.clickEvent {
//                print("🔗 [DEBUG]   \(key): \(value)")
//            }
//            print("🔗 [DEBUG] ===================================")
//        }
//        #endif
        
        deepLinkService.checkDeeplinkResult(with: result) { [weak self] value, params in
            guard let self = self else {
                return
            }
            print("🔗 [AppsFlyer] DeepLink service returned value: \(value)")
            
            if let params = params {
                print("🔗 [AppsFlyer] DeepLink params:")
                print("🔗   Key Type: \(params.keyType.description)")
                print("🔗   type1: \(params.afSub1)")
                print("🔗   type2: \(params.afAdset)")
                print("🔗   value1: \(params.deepLinkSub1)")
            }
            
//            #if DEBUG
//            // Для тестирования можно форсировать значение
//            if CommandLine.arguments.contains("--force-deeplink") {
//                let testValue = "test_value"
//                print("🔗 [DEBUG] Forcing test deep link value: \(testValue)")
//                self.attributionValue = testValue
//                self.deepLinkParams = params
//                UserDefaults.standard.set(testValue, forKey: "appsflyer_deep_link_key")
//                UserDefaults.standard.set(Date(), forKey: "appsflyer_deep_link_date_key")
//                if let params = params {
//                    self.saveDeepLinkParameters(params)
//                }
//                self.status = self.status.nextStatus
//                self.checkStatus()
//                return
//            }
//            #endif
            
            self.attributionValue = value
            self.deepLinkParams = params
            
            // Сохраняем в UserDefaults
            UserDefaults.standard.set(value, forKey: "appsflyer_deep_link_key")
            UserDefaults.standard.set(Date(), forKey: "appsflyer_deep_link_date_key")
            
            // Сохраняем параметры deep link
            if let params = params {
                self.saveDeepLinkParameters(params)
            }
            
            self.status = self.status.nextStatus
            self.checkStatus()
        }
    }
}

// MARK: - Private Extension

private extension AppsFlyerService {
    func checkStatus() {
        if status == .done {
            print("✅ [AppsFlyer] Attribution complete")
            print("✅ [AppsFlyer] Value: \(attributionValue)")
            if let params = deepLinkParams {
                print("✅ [AppsFlyer] DeepLink Params:")
                print("✅   Key Type: \(params.keyType.description)")
                print("✅   deep_link_value: \(params.deepLinkValue)")
                print("✅   af_sub1: \(params.afSub1)")
                print("✅   af_adset: \(params.afAdset)")
                print("✅   deep_link_sub1: \(params.deepLinkSub1)")
                print("✅   pid: \(params.pid)")
                print("✅   isDeferred: \(params.isDeferred)")
            }
            
            onFinish?(AttributionInfo(
                type: .appsflyer,
                value: attributionValue,
                attribution: attributionDict,
                deepLinkParams: deepLinkParams
            ))
        }
    }
}
