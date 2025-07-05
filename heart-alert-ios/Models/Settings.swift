import Foundation
import Combine

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var bpmLowerValue: Int
    @Published var bpmUpperValue: Int
    @Published var volume: Int
    @Published var vibrate: Bool

    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load from UserDefaults
        self.bpmLowerValue = UserDefaults.standard.object(forKey: "bpmLowerValue") as? Int ?? 110
        self.bpmUpperValue = UserDefaults.standard.object(forKey: "bpmUpperValue") as? Int ?? 140
        self.volume = UserDefaults.standard.object(forKey: "volume") as? Int ?? 90
        self.vibrate = UserDefaults.standard.object(forKey: "vibrate") as? Bool ?? false

        SoundManager.shared.start()
        SoundManager.shared.volume = Float(self.volume) / 100
        VibrationManager.shared.vibrate = self.vibrate
        
        // Automatically save to UserDefaults when values change
        $bpmLowerValue
            .sink { UserDefaults.standard.set($0, forKey: "bpmLowerValue") }
            .store(in: &cancellables)
        
        $bpmUpperValue
            .sink { UserDefaults.standard.set($0, forKey: "bpmUpperValue") }
            .store(in: &cancellables)

        $volume
            .sink {
                SoundManager.shared.volume = Float($0) / 100
                UserDefaults.standard.set($0, forKey: "volume")
            }
            .store(in: &cancellables)

        $vibrate
            .sink {
                VibrationManager.shared.vibrate = $0
                UserDefaults.standard.set($0, forKey: "vibrate")
            }
            .store(in: &cancellables)
    }
}
