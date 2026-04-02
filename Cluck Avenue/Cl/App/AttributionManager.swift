// AttributionManager.swift
import Foundation
import Combine

final class AttributionManager: ObservableObject {
    static let shared = AttributionManager()
    
    private let kAttributionCheckedKey = "attribution_checked"
    private let kIsNonOrganicKey = "is_non_organic"
    
    @Published var attributionChecked: Bool = false
    @Published var isNonOrganic: Bool = false
    
    private init() {}
    
    func loadCached() {
        // Проверяем, есть ли уже сохраненная атрибуция
        let cached = UserDefaults.standard.bool(forKey: kAttributionCheckedKey)
        if cached {
            // Если данные уже были сохранены ранее - используем только их
            self.isNonOrganic = UserDefaults.standard.bool(forKey: kIsNonOrganicKey)
            self.attributionChecked = true
            print("📱 [AttributionManager] Loaded from cache (permanent): \(self.isNonOrganic ? "non-organic" : "organic")")
        } else {
            print("📱 [AttributionManager] No cache found - first session, will process attribution")
        }
    }
    
    func handle(_ attribution: AttributionInfo) {
        // Проверяем, есть ли уже сохраненная атрибуция в кеше
        let alreadySaved = UserDefaults.standard.bool(forKey: kAttributionCheckedKey)
        
        if alreadySaved {
            print("📱 [AttributionManager] Attribution already saved permanently, skipping new attribution")
            return
        }
        
        guard !attributionChecked else {
            print("📱 [AttributionManager] Already handled in current session, skipping")
            return
        }
        
        var nonOrganic = false
        
        // 1. Проверяем deep link key
        if let params = attribution.deepLinkParams {
            print("📱 [AttributionManager] keyType: \(params.keyType.description)")
            switch params.keyType {
            case .on_1, .key1, .key2, .key3:
                nonOrganic = true
            case .unknown:
                break
            }
        }
        
        // 2. Если не определили по deep link — смотрим af_status
        if !nonOrganic {
            if let dict = attribution.attribution,
               let afStatus = dict["af_status"] as? String {
                print("📱 [AttributionManager] af_status: \(afStatus)")
                nonOrganic = afStatus.lowercased() != "organic"
            } else if !attribution.value.isEmpty {
                nonOrganic = true
            }
        }
        
        print("📱 [AttributionManager] Result: \(nonOrganic ? "non-organic" : "organic") - SAVING PERMANENTLY")
        
        // Сохраняем в кеш ОДИН РАЗ И НАВСЕГДА
        UserDefaults.standard.set(true, forKey: kAttributionCheckedKey)
        UserDefaults.standard.set(nonOrganic, forKey: kIsNonOrganicKey)
        
        DispatchQueue.main.async {
            self.isNonOrganic = nonOrganic
            self.attributionChecked = true
        }
    }
    
    func reset() {
        UserDefaults.standard.removeObject(forKey: kAttributionCheckedKey)
        UserDefaults.standard.removeObject(forKey: kIsNonOrganicKey)
        DispatchQueue.main.async {
            self.attributionChecked = false
            self.isNonOrganic = false
        }
        print("🧪 [AttributionManager] Cache cleared")
    }
}
