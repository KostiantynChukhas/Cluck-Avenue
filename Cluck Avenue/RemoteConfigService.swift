import Foundation
import Combine
import SwiftUI

/// Сервис для управления значениями из Firebase Remote Config
class RemoteConfigService: ObservableObject {
    static let shared = RemoteConfigService()
    
    // MARK: - Published Properties
    @Published var enableWView: Bool = false
    @Published var url: String = ""
    
    private init() {}
    
    // MARK: - Update Methods
    func updateValues(enableWView: Bool, url: String) {
        self.enableWView = enableWView
        self.url = url
        
        print("🔧 Remote Config updated:")
        print("   enableWView: \(enableWView)")
        print("   url: \(url)")
    }
    
    // MARK: - Reset
    func reset() {
        enableWView = false
        url = ""
    }
}
