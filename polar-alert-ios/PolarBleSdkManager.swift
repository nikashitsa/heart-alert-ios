import PolarBleSdk

class PolarBleSdkManager {
    static let shared = PolarBleSdkManager()
    var api: PolarBleApi?
    var deviceId: String?
    var statusLabel: UILabel?
    var status: String = "" {
        didSet {
            statusLabel?.text = status
        }
    }
    
    private init() {}
}
