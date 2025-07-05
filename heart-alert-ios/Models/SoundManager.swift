import AVFoundation

enum SoundType: String, CaseIterable {
    case lowBeep = "low_beep"
    case highBeep = "high_beep"
    case connected = "connected"
    case disconnected = "disconnected"
    case reconnecting = "reconnecting"
    case good = "good"
    case tooHigh = "too_high"
    case tooLow = "too_low"
}

class SoundManager {
    static let shared = SoundManager()
    
    private var engine: AVAudioEngine = AVAudioEngine()
    private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    private var playerNodes: [AVAudioPlayerNode] = []
    
    private var soundFiles: [SoundType: AVAudioFile] = [:]
    
    private var selectedNode = 0
    private let poolSize = 32
    
    var volume: Float = 1.0
    
    init() {
        for type in SoundType.allCases {
            soundFiles[type] = loadAudioFile(named: type.rawValue)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        switch type {
        case .began:
            print("Audio session interrupted")
        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                if !engine.isRunning {
                    try engine.start()
                }
            } catch {
                print("Failed to restart audio engine: \(error.localizedDescription)")
            }
        @unknown default:
            break
        }
    }
    
    func start() {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        
        playerNodes = []
        for _ in 0..<poolSize {
            playerNodes.append(AVAudioPlayerNode())
        }
        
        engine.attach(mixer)
        engine.connect(mixer, to: engine.outputNode, format: nil)
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        for playerNode in playerNodes {
            engine.attach(playerNode)
            engine.connect(playerNode, to: mixer, format: nil)
        }
        
        do {
            try self.engine.start()
        } catch let error {
            print("Error starting engine: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        for playerNode in playerNodes {
            playerNode.stop()
        }
        engine.stop()
    }
    
    func play(_ sound: SoundType) {
        if !self.engine.isRunning { return }
        let node: AVAudioPlayerNode = playerNodes[selectedNode]
        mixer.outputVolume = volume
        mixer.reset()
        selectedNode += 1
        if selectedNode > (playerNodes.count - 1) {
            selectedNode = 0
        }
        if node.isPlaying {
            node.stop()
        }
        node.scheduleFile(getSound(sound)!, at: nil, completionHandler: nil)
        node.play()
    }
    
    private func loadAudioFile(named name: String) -> AVAudioFile? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("Failed to find sound file: \(name).wav")
            return nil
        }
        return try? AVAudioFile(forReading: url)
    }

    func getSound(_ type: SoundType) -> AVAudioFile? {
        return soundFiles[type]
    }
}
