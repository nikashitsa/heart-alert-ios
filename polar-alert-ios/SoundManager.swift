import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var engine: AVAudioEngine = AVAudioEngine()
    private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    private var playerNodes: [AVAudioPlayerNode] = []
    
    private var lowBeepFile: AVAudioFile?
    private var highBeepFile: AVAudioFile?
    private var selectedNode = 0
    private let poolSize = 32
    
    var volume: Float = 1.0
    
    private init() {
        
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
    
        do {
            try lowBeepFile = AVAudioFile(forReading: Bundle.main.url(forResource: "low_beep", withExtension: ".wav")!)
            try highBeepFile = AVAudioFile(forReading: Bundle.main.url(forResource: "high_beep", withExtension: ".wav")!)
        } catch let error {
            print("Error opening audio file: \(error.localizedDescription)")
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
    
    func play(sound: String) {
        if (!self.engine.isRunning) { return }
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
        if (sound == "low") {
            node.scheduleFile(lowBeepFile!, at: nil, completionHandler: nil)
        } else if (sound == "high") {
            node.scheduleFile(highBeepFile!, at: nil, completionHandler: nil)
        } else {
            print("unknown sound")
        }
        node.play()
    }
}
