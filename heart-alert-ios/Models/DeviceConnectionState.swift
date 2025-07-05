import Foundation

enum DeviceConnectionState {
    case disconnected(String)
    case connecting(String)
    case connected(String)
}
