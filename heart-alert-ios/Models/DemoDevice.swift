import Foundation
import PolarBleSdk

/// The fake strap demo mode connects to.
///
/// Every demo branch in `BluetoothManager` keys off `addressString` rather than off
/// `Settings.demoMode`, so a connection already in flight cannot be stranded half-built if the
/// flag changes underneath it. No real device can present this address.
enum DemoDevice {
    static let address = UUID(uuidString: "DE30DE30-0000-4000-8000-000000000001")!
    static let addressString = address.uuidString
    static let name = "Demo Strap"
    static let batteryLevel: UInt = 87

    /// Strong RSSI so it sorts to the top of the picker's list.
    static let info = DeviceInfo(from: (
        deviceId: "DEMO0001",
        address: address,
        rssi: -30,
        name: name,
        connectable: true
    ))
}
