import UIKit
import PolarBleSdk

class SetupController: UIViewController,
                       UIPickerViewDelegate,
                       UIPickerViewDataSource {
    
    var api: PolarBleApi?
    var deviceId: String?
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var vibrateSwitch: UISwitch!
    @IBOutlet weak var rangeStackView: UIStackView!
    @IBOutlet weak var volumeStackView: UIStackView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var minBpmLabel: UILabel!
    @IBOutlet weak var maxBpmLabel: UILabel!
    @IBOutlet weak var vibrateLabel: UILabel!
    
    let bpmSlider = RangeSlider(frame: CGRect.zero)
    let volumeSlider = RangeSlider(frame: CGRect.zero)
    
    var bpmArray: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SoundManager.shared.start()
        self.api = PolarBleSdkManager.shared.api!
        self.deviceId = PolarBleSdkManager.shared.deviceId!
          
        startButton.layer.borderColor = UIColor.white.cgColor
        startButton.layer.cornerRadius = 0.0
        startButton.layer.borderWidth = 1.0
        
        vibrateSwitch.layer.borderColor = UIColor.white.cgColor
        vibrateSwitch.layer.cornerRadius = 16.0
        vibrateSwitch.layer.borderWidth = 1.0
        vibrateSwitch.isOn = Settings.shared.vibrate
        vibrateLabel.text = vibrateSwitch.isOn ? "Vibrate ON" : "Vibrate OFF"
                
        bpmSlider.maximumValue = 220.0
        bpmSlider.minimumValue = 40.0
        bpmSlider.lowerValue = Double(Settings.shared.bpmLowerValue)
        bpmSlider.upperValue = Double(Settings.shared.bpmUpperValue)
        minBpmLabel.text = String(Int(bpmSlider.lowerValue))
        maxBpmLabel.text = "\(Int(bpmSlider.upperValue)) BPM"
        bpmSlider.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
        bpmSlider.addTarget(self, action: #selector(SetupController.bpmSliderValueChanged(_:)), for: .valueChanged)
        rangeStackView.addArrangedSubview(bpmSlider)
        
        volumeSlider.maximumValue = 100.0
        volumeSlider.minimumValue = 0.0
        volumeSlider.lowerValue = -1.0
        volumeSlider.upperValue = Double(Settings.shared.volume)
        volumeLabel.text = "Volume \(Int(volumeSlider.upperValue))%"
        SoundManager.shared.volume = Float(Int(volumeSlider.upperValue)) / 100
        volumeSlider.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
        volumeSlider.addTarget(self, action: #selector(SetupController.volumeSliderValueChanged(_:)), for: .valueChanged)
        volumeStackView.addArrangedSubview(volumeSlider)
                
        minBpmLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SetupController.minBpmClick)))
        maxBpmLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SetupController.maxBpmClick)))
        
        vibrateSwitch.addTarget(self, action: #selector(SetupController.vibrateSwitchChanged(_:)), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        statusLabel.text = PolarBleSdkManager.shared.status
        PolarBleSdkManager.shared.statusLabel = statusLabel
    }
    
    @objc func bpmSliderValueChanged(_ rangeSlider: RangeSlider) {
        let min = String(Int(rangeSlider.lowerValue))
        if (min != minBpmLabel.text) {
            minBpmLabel.text = String(Int(rangeSlider.lowerValue))
            Settings.shared.bpmLowerValue = Int(rangeSlider.lowerValue)
        }
        let max = "\(Int(rangeSlider.upperValue)) BPM"
        if (max != maxBpmLabel.text) {
            maxBpmLabel.text = "\(Int(rangeSlider.upperValue)) BPM"
            Settings.shared.bpmUpperValue = Int(rangeSlider.upperValue)
        }
    }
    
    @IBAction func minBpmClick(sender: UITapGestureRecognizer) {
        let vc = UIViewController()
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.tag = 1
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        bpmArray = Array(Int(bpmSlider.minimumValue)...Int(bpmSlider.upperValue))
        pickerView.selectRow(bpmArray.firstIndex(of: Int(bpmSlider.lowerValue))!, inComponent: 0, animated: false)
        let alert = UIAlertController(title: "Choose min BPM", message: "", preferredStyle: .alert)
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (UIAlertAction) in
            self.bpmSlider.lowerValue = Double(self.bpmArray[pickerView.selectedRow(inComponent: 0)])
            self.bpmSliderValueChanged(self.bpmSlider)
        }))
        vc.preferredContentSize = CGSize(width: self.view.bounds.width, height: 60 * 4)
        vc.view.addSubview(pickerView)
        pickerView.frame = vc.view.bounds
        pickerView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 0).isActive = true
        pickerView.leftAnchor.constraint(equalTo: vc.view.leftAnchor, constant: 0).isActive = true
        pickerView.rightAnchor.constraint(equalTo: vc.view.rightAnchor, constant: 0).isActive = true
        pickerView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: 0).isActive = true
        self.present(alert, animated: false, completion: nil)
    }
    
    @IBAction func maxBpmClick(sender: UITapGestureRecognizer) {
        let vc = UIViewController()
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.tag = 1
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        bpmArray = Array(Int(bpmSlider.lowerValue)...Int(bpmSlider.maximumValue))
        pickerView.selectRow(bpmArray.firstIndex(of: Int(bpmSlider.upperValue))!, inComponent: 0, animated: false)
        let alert = UIAlertController(title: "Choose max BPM", message: "", preferredStyle: .alert)
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (UIAlertAction) in
            self.bpmSlider.upperValue = Double(self.bpmArray[pickerView.selectedRow(inComponent: 0)])
            self.bpmSliderValueChanged(self.bpmSlider)
        }))
        vc.preferredContentSize = CGSize(width: self.view.bounds.width, height: 60 * 4)
        vc.view.addSubview(pickerView)
        pickerView.frame = vc.view.bounds
        pickerView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 0).isActive = true
        pickerView.leftAnchor.constraint(equalTo: vc.view.leftAnchor, constant: 0).isActive = true
        pickerView.rightAnchor.constraint(equalTo: vc.view.rightAnchor, constant: 0).isActive = true
        pickerView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: 0).isActive = true
        self.present(alert, animated: false, completion: nil)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.text = String(bpmArray[row])
        label.sizeToFit()
        return label
    }
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return bpmArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
    {
        return 60
    }
        
    @objc func volumeSliderValueChanged(_ rangeSlider: RangeSlider) {
        let label = "Volume \(Int(rangeSlider.upperValue))%"
        if (label != volumeLabel.text) {
            volumeLabel.text = label
            SoundManager.shared.volume = Float(Int(rangeSlider.upperValue)) / 100
            Settings.shared.volume = Int(rangeSlider.upperValue)
            SoundManager.shared.play(sound: "low")
        }
    }
    
    @objc func vibrateSwitchChanged(_ switcher: UISwitch) {
        if (switcher.isOn) {
            vibrateLabel.text = "Vibrate ON"
            Settings.shared.vibrate = true
        } else {
            vibrateLabel.text = "Vibrate OFF"
            Settings.shared.vibrate = false
        }
    }
    
    @IBAction func startClick(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let runVc = storyboard.instantiateViewController(identifier: "RunController") as RunController        
        runVc.lowerValue = UInt8(bpmSlider.lowerValue)
        runVc.upperValue = UInt8(bpmSlider.upperValue)
        runVc.vibration = vibrateSwitch.isOn
        print(runVc.lowerValue, runVc.upperValue, runVc.vibration)
        runVc.modalPresentationStyle = .fullScreen
        present(runVc, animated: false, completion: nil)
    }
    
    @IBAction func backClick(_ sender: UIButton) {
        do {
            try self.api!.disconnectFromDevice(self.deviceId!)
        } catch let err {
            print("Failed to disconnect from \(self.deviceId!). Reason \(err)")
        }
        SoundManager.shared.stop()
        self.dismiss(animated: true, completion: nil)
    }
}
