import Foundation
import PolarBleSdk
import RxSwift
import CoreBluetooth

class BluetoothManager: ObservableObject {
    private var api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main,
                                                                 features: [
                                                                    PolarBleSdkFeature.feature_hr,
                                                                    PolarBleSdkFeature.feature_battery_info
                                                                 ]
    )
    
    @Published var isBluetoothOn: Bool
    @Published var isBroadcastListenOn: Bool = false
    
    @Published var deviceConnectionState: DeviceConnectionState = DeviceConnectionState.disconnected("")
    @Published var deviceName: String = ""
    @Published var deviceAddress: String = ""
    @Published var foundDevices: [DeviceInfo] = []
    @Published var hrFeature: HrFeature = HrFeature()
    @Published var batteryStatusFeature: BatteryStatusFeature = BatteryStatusFeature()
    
    private var broadcastDisposable: Disposable?
    private var autoConnectDisposable: Disposable?
    private var onlineStreamingDisposables: [PolarDeviceDataType: Disposable?] = [:]
    
    private var searchDevicesTask: Task<Void, Never>? = nil
    
    init() {
        self.isBluetoothOn = api.isBlePowered
        
        api.observer = self
        api.deviceFeaturesObserver = self
        api.powerStateObserver = self
        api.deviceInfoObserver = self
    }
    
    func updateSelectedDevice(address: String) {
        if case .disconnected = deviceConnectionState {
            self.deviceConnectionState = DeviceConnectionState.disconnected(address)
        }
    }
    
    func connectToDevice() {
        if case .disconnected(let deviceId) = deviceConnectionState {
            do {
                try api.connectToDevice(deviceId)
            } catch let err {
                NSLog("Failed to connect to \(deviceId). Reason \(err)")
            }
        }
    }
    
    func disconnectFromDevice() {
        if case .connected(let deviceId) = deviceConnectionState {
            do {
                try api.disconnectFromDevice(deviceId)
            } catch let err {
                NSLog("Failed to disconnect from \(deviceId). Reason \(err)")
            }
        }
    }
    
    func autoConnect() {
        autoConnectDisposable?.dispose()
        autoConnectDisposable = api.startAutoConnectToDevice(-55, service: nil, polarDeviceType: nil)
            .subscribe{ e in
                switch e {
                case .completed:
                    NSLog("auto connect search complete")
                case .error(let err):
                    NSLog("auto connect failed: \(err)")
                }
            }
    }
    
    func startDevicesSearch() {
        searchDevicesTask = Task {
            await searchDevicesAsync()
        }
    }
    
    func stopDevicesSearch() {
        searchDevicesTask?.cancel()
        searchDevicesTask = nil
        foundDevices.removeAll()
    }
    
    private func searchDevicesAsync() async {
        do {
            for try await value in api.searchForDevice().values {
                Task { @MainActor in
                    self.foundDevices.append(DeviceInfo(from: value))
                }
            }
        } catch let err {
            let deviceSearchFailed = "device search failed: \(err)"
            NSLog(deviceSearchFailed)
        }
    }
    
    func onlineStreamStop(feature: PolarBleSdk.PolarDeviceDataType) {
        onlineStreamingDisposables[feature]??.dispose()
    }
    
    func hrStreamStart(_ onBeat: @escaping (UInt8) -> Void) {
        if case .connected(let deviceId) = deviceConnectionState {
            onlineStreamingDisposables[.hr] = api.startHrStreaming(deviceId)
                .do(onDispose: {})
                .subscribe{ e in
                    switch e {
                    case .next(let data):
                        onBeat(data[0].hr)
                    case .error(let err):
                        NSLog("Hr stream failed: \(err)")
                    case .completed:
                        NSLog("Hr stream completed")
                    }
                }
        } else {
            NSLog("Device is not connected \(deviceConnectionState)")
        }
    }
}

// MARK: - PolarBleApiPowerStateObserver
extension BluetoothManager : PolarBleApiPowerStateObserver {
    func blePowerOn() {
        NSLog("BLE ON")
        Task { @MainActor in
            isBluetoothOn = true
        }
    }
    
    func blePowerOff() {
        NSLog("BLE OFF")
        Task { @MainActor in
            isBluetoothOn = false
        }
    }
}

// MARK: - PolarBleApiObserver
extension BluetoothManager : PolarBleApiObserver {
    func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
        NSLog("DEVICE CONNECTING: \(polarDeviceInfo)")
        Task { @MainActor in
            self.deviceConnectionState = DeviceConnectionState.connecting(polarDeviceInfo.address.uuidString)
        }
    }
    
    func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
        NSLog("DEVICE CONNECTED: \(polarDeviceInfo)")
        print(polarDeviceInfo.name)
        Task { @MainActor in
            self.deviceName = polarDeviceInfo.name
            self.deviceAddress = polarDeviceInfo.address.uuidString
            self.deviceConnectionState = DeviceConnectionState.connected(polarDeviceInfo.address.uuidString)
        }
    }
    
    func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo, pairingError: Bool) {
        NSLog("DISCONNECTED: \(polarDeviceInfo)")
        Task { @MainActor in
            self.deviceConnectionState = DeviceConnectionState.disconnected(polarDeviceInfo.address.uuidString)
            self.hrFeature = HrFeature()
            self.batteryStatusFeature = BatteryStatusFeature()
        }
    }
}

// MARK: - PolarBleApiDeviceFeaturesObserver
extension BluetoothManager : PolarBleApiDeviceFeaturesObserver {
    func bleSdkFeatureReady(_ identifier: String, feature: PolarBleSdk.PolarBleSdkFeature) {
        NSLog("Feature is ready: \(feature)")
        if case .feature_hr = feature {
            Task { @MainActor in
                self.hrFeature.isSupported = true
            }
        } else if case .feature_battery_info = feature {
            Task { @MainActor in
                self.batteryStatusFeature.isSupported = true
            }
        }
    }
}

// MARK: - PolarBleApiDeviceInfoObserver
extension BluetoothManager : PolarBleApiDeviceInfoObserver {
    func batteryChargingStatusReceived(_ identifier: String, chargingStatus: PolarBleSdk.BleBasClient.ChargeState) {
    }
    
    func disInformationReceivedWithKeysAsStrings(_ identifier: String, key: String, value: String) {
    }
  
    func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        NSLog("battery level updated: \(batteryLevel)")
        Task { @MainActor in
            self.batteryStatusFeature.batteryLevel = batteryLevel
        }
    }
    
    func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {
    }
}
