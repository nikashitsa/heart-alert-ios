import Foundation
import Combine

class Settings: ObservableObject {
    static let shared = Settings()

    // Seconds
    static let alertIntervalOptions = [1, 3, 5, 10]
    static let outOfRangeForOptions = [0, 5, 10, 30, 60, 300, 600]

    // Seconds, plus a sentinel: hold alerts until BPM first enters the range
    static let initialDelayUntilInRange = -1
    static let initialDelayOptions = [0, initialDelayUntilInRange, 60, 300, 600, 900]
    static let initialDelayLabels = [0: "off", initialDelayUntilInRange: "until in range"]

    @Published var bpmLowerValue: Int
    @Published var bpmUpperValue: Int
    @Published var volume: Int
    @Published var vibrate: Bool
    @Published var alertInterval: Int
    @Published var outOfRangeFor: Int
    @Published var initialDelay: Int

    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load from UserDefaults
        self.bpmLowerValue = UserDefaults.standard.object(forKey: "bpmLowerValue") as? Int ?? 110
        self.bpmUpperValue = UserDefaults.standard.object(forKey: "bpmUpperValue") as? Int ?? 140
        self.volume = UserDefaults.standard.object(forKey: "volume") as? Int ?? 90
        self.vibrate = UserDefaults.standard.object(forKey: "vibrate") as? Bool ?? false
        self.alertInterval = UserDefaults.standard.object(forKey: "alertInterval") as? Int ?? 1
        self.outOfRangeFor = UserDefaults.standard.object(forKey: "outOfRangeFor") as? Int ?? 0
        self.initialDelay = UserDefaults.standard.object(forKey: "initialDelay") as? Int ?? 0

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

        $alertInterval
            .sink { UserDefaults.standard.set($0, forKey: "alertInterval") }
            .store(in: &cancellables)

        $outOfRangeFor
            .sink { UserDefaults.standard.set($0, forKey: "outOfRangeFor") }
            .store(in: &cancellables)

        $initialDelay
            .sink { UserDefaults.standard.set($0, forKey: "initialDelay") }
            .store(in: &cancellables)
    }
}
