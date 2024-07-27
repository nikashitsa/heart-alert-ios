import UIKit
import CoreBluetooth
import PolarBleSdk
import RxSwift

class MainController: UIViewController,
                      UIPickerViewDelegate,
                      UIPickerViewDataSource,
                      PolarBleApiObserver,
                      PolarBleApiDeviceFeaturesObserver {
    
    var api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main,
                                                         features: [
                                                            PolarBleSdkFeature.feature_hr
                                                         ])
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    private var selectedRow = 0
    private var searchDevicesTask: Task<Void, Error>? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        api.observer = self
        api.deviceFeaturesObserver = self
                
        PolarBleSdkManager.shared.api = api
        
        connectButton.layer.borderColor = UIColor.white.cgColor
        connectButton.layer.cornerRadius = 0.0
        connectButton.layer.borderWidth = 1.0
    }
    
    var devices : [(String, String)] = []
    
    @IBAction func connectClick(_ sender: UIButton) {
        if (!api.isBlePowered) {
            let alert = UIAlertController(title: "Bluetooth is Off", message: "Please enable Bluetooth on your device to continue.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        let vc = UIViewController()
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        
        let loginSpinner: UIActivityIndicatorView = {
            let loginSpinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
            loginSpinner.translatesAutoresizingMaskIntoConstraints = false
            loginSpinner.startAnimating()
            return loginSpinner
        }()
        vc.view.addSubview(loginSpinner)
        loginSpinner.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
        loginSpinner.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
          
        let alert = UIAlertController(title: "Searching Polar device", message: "", preferredStyle: .alert)
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
            self.devices.removeAll()
            self.searchDevicesTask?.cancel()
            self.searchDevicesTask = nil
        }))
        
        self.present(alert, animated: true, completion: nil)
        
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 10 * 1_000_000_000) // 10 sec
            self.searchDevicesTask?.cancel()
            self.searchDevicesTask = nil
            loginSpinner.removeFromSuperview()
            alert.title = "Polar device not found"
            alert.setValue(nil, forKey: "contentViewController")
            alert.message = "Make sure that you put it on and that the battery level is good."
        }
        
        searchDevicesTask = Task { @MainActor in
            for try await value: PolarDeviceInfo in self.api.searchForDevice().values {
                if (self.devices.count == 0) {
                    timeoutTask.cancel()
                    loginSpinner.removeFromSuperview()
                    alert.title = "Choose device"
                    alert.addAction(UIAlertAction(title: "Connect", style: .default, handler: { (UIAlertAction) in
                        self.connectButton.isHidden = true
                        self.loadingIndicator.isHidden = false
                        self.searchDevicesTask?.cancel()
                        self.searchDevicesTask = nil
                        self.selectedRow = pickerView.selectedRow(inComponent: 0)
                        PolarBleSdkManager.shared.deviceId = self.devices[self.selectedRow].0
                        self.devices.removeAll()
                        
                        do {
                            try self.api.connectToDevice(PolarBleSdkManager.shared.deviceId!)
                        } catch let err {
                            self.loadingIndicator.isHidden = true
                            self.connectButton.isHidden = false
                            print("Failed to connect to \(PolarBleSdkManager.shared.deviceId!). Reason \(err)")
                        }
                    }))
                    vc.preferredContentSize = CGSize(width: self.view.bounds.width, height: 60 * 4)
                    pickerView.frame = vc.view.bounds
                    vc.view.addSubview(pickerView)
                }
                self.devices.append((value.deviceId, value.name))
                pickerView.reloadAllComponents()
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let label = UILabel()
        label.text = devices[row].1
        label.sizeToFit()
        return label
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        devices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
    {
        return 60
    }
    
    func deviceConnecting(_ identifier: PolarBleSdk.PolarDeviceInfo) {
        print("DEVICE CONNECTING: \(identifier)")
        PolarBleSdkManager.shared.status = "Reconnecting…"
    }

    func deviceConnected(_ identifier: PolarBleSdk.PolarDeviceInfo) {
        print("DEVICE CONNECTED: \(identifier)")
        PolarBleSdkManager.shared.status = "Connected"
    }

    func deviceDisconnected(_ identifier: PolarBleSdk.PolarDeviceInfo, pairingError: Bool) {
        print("DISCONNECTED: \(identifier)")
        PolarBleSdkManager.shared.status = "Disconnected"
    }

    func hrFeatureReady(_ identifier: String) {
        print("HR READY.")
        if (self.view.window == nil) { return }        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let setupVc = storyboard.instantiateViewController(identifier: "SetupController")
        setupVc.modalPresentationStyle = .fullScreen
        setupVc.modalTransitionStyle = .flipHorizontal
        present(setupVc, animated: true, completion: {
            self.loadingIndicator.isHidden = true
            self.connectButton.isHidden = false
        })
    }
    
    func ftpFeatureReady(_ identifier: String) {
    
    }
    func streamingFeaturesReady(_ identifier: String, streamingFeatures: Set<PolarBleSdk.PolarDeviceDataType>) {
    
    }
    func bleSdkFeatureReady(_ identifier: String, feature: PolarBleSdk.PolarBleSdkFeature) {
    
    }
}
