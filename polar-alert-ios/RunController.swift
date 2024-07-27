import UIKit
import PolarBleSdk
import RxSwift
import AVFoundation

class RunController: UIViewController {
    
    var api: PolarBleApi?
    var deviceId: String?
    var hr: Disposable?
    var upperValue: UInt8 = 0
    var lowerValue: UInt8 = 0
    var vibration: Bool = false
    
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bpmDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.api = PolarBleSdkManager.shared.api!
        self.deviceId = PolarBleSdkManager.shared.deviceId!
        
        stopButton.layer.borderColor = UIColor.white.cgColor
        stopButton.layer.cornerRadius = 0.0
        stopButton.layer.borderWidth = 1.0
        
        hr = api!.startHrStreaming(deviceId!)
            .do(onDispose: {})
            .subscribe{ e in
                switch e {
                case .next(let data):
                    Task { @MainActor in
                        self.bpmLabel.text = "\(data[0].hr) BPM"
                        if (data[0].hr > self.upperValue) {
                            self.pulse(mode: "high")
                        } else if (data[0].hr < self.lowerValue) {
                            self.pulse(mode: "low")
                        } else {
                            self.pulse()
                        }
                    }
                case .error(let err):
                    print("Hr stream failed: \(err)")
                case .completed:
                    print("Hr stream completed")
                }
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        statusLabel.text = PolarBleSdkManager.shared.status
        PolarBleSdkManager.shared.statusLabel = statusLabel
    }
    
    func pulse(mode: String = "") {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.15
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 0.9
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 1
        bpmLabel.layer.add(pulseAnimation, forKey: "pulse")
        
        if (mode == "low") {
            bpmDescriptionLabel.text = "Too low!"
            bpmLabel.textColor = UIColor.red
            SoundManager.shared.play(sound: "low")
            if (vibration) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        } else if (mode == "high") {
            bpmDescriptionLabel.text = "Too high!"
            bpmLabel.textColor = UIColor.red
            SoundManager.shared.play(sound: "high")
            if (vibration) {
                AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                })
            }
        } else {
            bpmLabel.textColor = UIColor.white
            bpmDescriptionLabel.text = "Good"
        }
    }
    
    @IBAction func stopClick(_ sender: UIButton) {
        hr?.dispose()
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func backClick(_ sender: UIButton) {
        hr?.dispose()
        self.dismiss(animated: false, completion: nil)
    }
    
}
