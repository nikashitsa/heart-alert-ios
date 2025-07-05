import Foundation
import PolarBleSdk

struct DeviceInfo: Identifiable, Hashable, Equatable {
    let id: String
    
    let deviceId: String
    let address: UUID
    let rssi: Int
    let name: String
    let connectable: Bool

    init(from tuple: PolarDeviceInfo) {
        self.deviceId = tuple.deviceId
        self.address = tuple.address
        self.rssi = tuple.rssi
        self.name = tuple.name
        self.connectable = tuple.connectable
        self.id = "\(tuple.deviceId)-\(tuple.address.uuidString)"
    }
}
