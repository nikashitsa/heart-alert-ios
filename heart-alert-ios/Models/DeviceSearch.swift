import Foundation
import PolarBleSdk

enum DeviceSearchState {
    case inProgress
    case success
    case failed(error: String)
}

extension DeviceSearchState: Equatable {
    static func == (lhs: DeviceSearchState, rhs: DeviceSearchState) -> Bool {
        switch (lhs, rhs) {
        case (.inProgress, .inProgress):
            return true
        case (.success, .success):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

struct DeviceSearch: Identifiable {
    let id = UUID()
    var isSearching: DeviceSearchState = .success
    var foundDevices = [DeviceInfo]()
}

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
