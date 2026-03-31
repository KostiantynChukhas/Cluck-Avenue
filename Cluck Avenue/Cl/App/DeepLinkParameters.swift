import Foundation
import AppsFlyerLib

struct DeepLinkParameters {
    let deepLinkValue: String      // key1, key2, key3
    let afSub1: String             // type1
    let afAdset: String            // type2
    let deepLinkSub1: String       // value1
    let pid: String                // User_invite
    let isDeferred: Bool
    let allParameters: [AnyHashable: Any]
    
    init(from deepLink: DeepLink) {
        self.deepLinkValue = deepLink.deeplinkValue ?? ""
        self.afSub1 = deepLink.clickEvent["af_sub1"] as? String ?? ""
        self.afAdset = deepLink.clickEvent["af_adset"] as? String ?? ""
        self.deepLinkSub1 = deepLink.clickEvent["deep_link_sub1"] as? String ?? ""
        self.pid = deepLink.clickEvent["pid"] as? String ?? ""
        self.isDeferred = deepLink.isDeferred
        self.allParameters = deepLink.clickEvent
    }
    
    // Вспомогательный метод для проверки типа ключа
    var keyType: DeepLinkKeyType {
        switch deepLinkValue.lowercased() {
        case "key1":
            return .key1
        case "key2":
            return .key2
        case "key3":
            return .key3
        default:
            return .unknown
        }
    }
}

// Enum для типов ключей
enum DeepLinkKeyType {
    case key1
    case key2
    case key3
    case unknown
    
    var description: String {
        switch self {
        case .key1: return "Key 1 Flow"
        case .key2: return "Key 2 Flow"
        case .key3: return "Key 3 Flow"
        case .unknown: return "Unknown Flow"
        }
    }
}
