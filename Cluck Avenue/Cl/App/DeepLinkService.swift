import Foundation
import AppsFlyerLib

protocol DeepLinkServiceProtocol {
    func checkDeeplinkResult(with result: DeepLinkResult, onFinish: ((String, DeepLinkParameters?) -> Void)?)
}

class DeepLinkService: DeepLinkServiceProtocol {
    
    private enum Const {
        static let defaultValue: String = ""
        static let delayInterval: Double = 1
    }
    
    private var setterTimer: Timer?
    private var deepLinkTypeWasSetted: Bool = false
    
    func checkDeeplinkResult(with result: DeepLinkResult, onFinish: ((String, DeepLinkParameters?) -> Void)?) {
        guard deepLinkTypeWasSetted == false else { return }
        
        switch result.status {
        case .notFound:
            print("🔗 [DeepLink] Deep link not found")
            setDeepLinkValueWithDelay(value: Const.defaultValue, params: nil, onFinish: onFinish)
            
        case .failure:
            print("🔗 [DeepLink] Deep link error: \(result.error?.localizedDescription ?? "unknown")")
            setDeepLinkValueWithDelay(value: Const.defaultValue, params: nil, onFinish: onFinish)
            
        case .found:
            print("🔗 [DeepLink] Deep link found!")
            if let deepLinkObj = result.deepLink {
                // Создаем объект с параметрами
                let params = DeepLinkParameters(from: deepLinkObj)
                
                // Определяем тип ключа
                let keyType = params.keyType
                
                // Логируем все параметры
                print("🔗 [DeepLink] ===== DEEP LINK DETECTED =====")
                print("🔗 [DeepLink] Key Type: \(keyType.description)")
                print("🔗 [DeepLink] deep_link_value: \(params.deepLinkValue)")
                print("🔗 [DeepLink] af_sub1 (type1): \(params.afSub1)")
                print("🔗 [DeepLink] af_adset (type2): \(params.afAdset)")
                print("🔗 [DeepLink] deep_link_sub1 (value1): \(params.deepLinkSub1)")
                print("🔗 [DeepLink] pid: \(params.pid)")
                print("🔗 [DeepLink] isDeferred: \(params.isDeferred)")
                print("🔗 [DeepLink] ==============================")
                
                #if DEBUG
                // В дебаг режиме выводим все параметры
                print("🔗 [DEBUG] All click event parameters:")
                for (key, value) in deepLinkObj.clickEvent {
                    print("🔗 [DEBUG]   \(key): \(value)")
                }
                #endif
                
                // Валидация ключа
                switch keyType {
                case .key1:
                    print("✅ [DeepLink] Valid key1 detected - proceeding with key1 flow")
                case .key2:
                    print("✅ [DeepLink] Valid key2 detected - proceeding with key2 flow")
                case .key3:
                    print("✅ [DeepLink] Valid key3 detected - proceeding with key3 flow")
                case .unknown:
                    print("⚠️ [DeepLink] Unknown key value: \(params.deepLinkValue)")
                case .on_1:
                    print("✅ [DeepLink] Valid key3 detected - proceeding with on_1 flow")
                }
                
                setDeepLinkValueWithDelay(
                    value: deepLinkObj.deeplinkValue ?? Const.defaultValue,
                    params: params,
                    onFinish: onFinish
                )
            } else {
                print("🔗 [DeepLink] Could not extract deep link object")
                setDeepLinkValueWithDelay(value: Const.defaultValue, params: nil, onFinish: onFinish)
            }
        }
    }
}

private extension DeepLinkService {
    func setDeepLinkValueWithDelay(value: String, params: DeepLinkParameters?, onFinish: ((String, DeepLinkParameters?) -> Void)?) {
        setterTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: Const.delayInterval, repeats: false) { timer in
            self.setDeepLinkValue(with: value, params: params, onFinish: onFinish)
        }
        setterTimer = timer
    }
    
    func setDeepLinkValue(with value: String, params: DeepLinkParameters?, onFinish: ((String, DeepLinkParameters?) -> Void)?) {
        deepLinkTypeWasSetted = true
        print("🔗 [DeepLink] Setting deep link value: \(value)")
        onFinish?(value, params)
    }
}
