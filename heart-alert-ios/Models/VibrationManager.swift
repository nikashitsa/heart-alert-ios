import AVFoundation

class VibrationManager {
    static let shared = VibrationManager()
    var vibrate: Bool = false
        
    public func play(_ state: TrackingState) {
        if vibrate {
            if (state == .low) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            } else if (state == .high) {
                AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                })
            }
        }
    }
}
