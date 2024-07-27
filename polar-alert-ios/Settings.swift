import Foundation

class Settings {
    static let shared = Settings()
    
    private init() {}
    
    var bpmLowerValue: Int {
        get {
            if (UserDefaults.standard.object(forKey: "bpmLowerValue") == nil) {
                return 110
            } else {
                return UserDefaults.standard.integer(forKey: "bpmLowerValue")
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "bpmLowerValue")
        }
    }
    
    var bpmUpperValue: Int {
        get {
            if (UserDefaults.standard.object(forKey: "bpmUpperValue") == nil) {
                return 140
            } else {
                return UserDefaults.standard.integer(forKey: "bpmUpperValue")
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "bpmUpperValue")
        }
    }
    
    var volume: Int {
        get {
            if (UserDefaults.standard.object(forKey: "volume") == nil) {
                return 90
            } else {
                return UserDefaults.standard.integer(forKey: "volume")
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "volume")
        }
    }
    
    var vibrate: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "vibrate")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "vibrate")
        }
    }
}
