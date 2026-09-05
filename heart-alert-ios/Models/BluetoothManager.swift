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

    private var demoSeedTask: Task<Void, Never>? = nil
    private var demoConnectTask: Task<Void, Never>? = nil
    private var demoHrTask: Task<Void, Never>? = nil

    private func isDemoAddress(_ address: String) -> Bool { address == DemoDevice.addressString }

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
            if isDemoAddress(deviceId) {
                return demoConnect(deviceId)
            }
            do {
                try api.connectToDevice(deviceId)
            } catch let err {
                NSLog("Failed to connect to \(deviceId). Reason \(err)")
            }
        }
    }

    func disconnectFromDevice() {
        // The real guard only accepts .connected. Demo also accepts .connecting, or a
        // connection interrupted mid-handshake would sit there forever and hang
        // DevicePickerView.connect(), which waits for .disconnected before reconnecting.
        let deviceId: String
        switch deviceConnectionState {
        case .connected(let id):
            deviceId = id
        case .connecting(let id) where isDemoAddress(id):
            deviceId = id
        default:
            return
        }
        if isDemoAddress(deviceId) {
            return demoDisconnect(deviceId)
        }
        do {
            try api.disconnectFromDevice(deviceId)
        } catch let err {
            NSLog("Failed to disconnect from \(deviceId). Reason \(err)")
        }
    }

    /// - Important: main actor only, and it must publish `.connecting` and `.connected` in
    ///   separate turns. `DevicePickerView.connect()` consumes this through
    ///   `$deviceConnectionState.values`, an AsyncPublisher with a demand of one: it replays
    ///   the current value when it attaches, but anything published while demand is zero is
    ///   dropped rather than queued. Two writes in one turn would lose `.connected` and hang
    ///   the picker on "Connecting..." forever — that branch has no timeout.
    private func demoConnect(_ deviceId: String) {
        demoConnectTask?.cancel()
        deviceConnectionState = .connecting(deviceId) // this turn: replayed on attach
        demoConnectTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled, let self else { return }
            // A disconnect, or a second attempt, during the sleep wins.
            guard case .connecting(let id) = self.deviceConnectionState, id == deviceId else { return }
            // Separate publishers, so these cannot steal demand from deviceConnectionState.
            self.deviceName = DemoDevice.name
            self.deviceAddress = deviceId
            self.hrFeature = HrFeature(isSupported: true)
            self.batteryStatusFeature = BatteryStatusFeature(isSupported: true,
                                                             batteryLevel: DemoDevice.batteryLevel)
            self.deviceConnectionState = .connected(deviceId) // next turn: the one delivery
        }
    }

    /// Synchronous on purpose: `connect()` attaches its first loop after this returns, so
    /// `.disconnected` is replayed and nothing has to be delivered at all.
    private func demoDisconnect(_ deviceId: String) {
        demoConnectTask?.cancel()
        demoConnectTask = nil
        demoHrTask?.cancel()
        demoHrTask = nil
        hrFeature = HrFeature()
        batteryStatusFeature = BatteryStatusFeature()
        deviceConnectionState = .disconnected(deviceId)
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
        // Demo mode offers the fake strap and nothing else: the real scan never starts, so a
        // real device in the room cannot appear beside it and be picked by mistake.
        guard !Settings.shared.demoMode else {
            // Seeded on a delay so it reads as a discovery rather than appearing
            // pre-populated, and well inside the picker's 10s "not found" timeout.
            demoSeedTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 600_000_000)
                guard !Task.isCancelled, let self else { return }
                // Guard against a double start; nothing here dedupes.
                guard !self.foundDevices.contains(where: { $0.id == DemoDevice.info.id }) else { return }
                self.foundDevices.append(DemoDevice.info)
            }
            return
        }

        searchDevicesTask = Task {
            await searchDevicesAsync()
        }
    }

    func stopDevicesSearch() {
        searchDevicesTask?.cancel()
        searchDevicesTask = nil
        demoSeedTask?.cancel()
        demoSeedTask = nil
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
        if feature == .hr {
            demoHrTask?.cancel()
            demoHrTask = nil
        }
        onlineStreamingDisposables[feature]??.dispose()
    }

    func hrStreamStart(_ onBeat: @escaping (UInt8) -> Void) {
        if case .connected(let deviceId) = deviceConnectionState, isDemoAddress(deviceId) {
            return demoHrStart(onBeat)
        }
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

    /// A triangle wave that always crosses both of the user's limits, so every alert fires
    /// without the reviewer touching anything. Delivered on the main actor to match the real
    /// stream, which the SDK dispatches on DispatchQueue.main.
    private func demoHrStart(_ onBeat: @escaping (UInt8) -> Void) {
        // bpmReadout()'s .onAppear re-fires whenever the connection state blips, so this has
        // to be idempotent or the sweeps stack up.
        demoHrTask?.cancel()
        demoHrTask = Task { @MainActor in
            let start = Date()
            let period: TimeInterval = 48 // one full sweep down and back

            while !Task.isCancelled {
                // Re-read every tick: the reviewer can change the range from Settings.
                // Reaching past the pickers' own 30...240 bounds is deliberate — TrackingState
                // compares strictly, so clamping to 30 would never fire "Too low!" for someone
                // who sets the minimum to 30.
                let low = Double(max(20, Settings.shared.bpmLowerValue - 20))
                let high = Double(min(250, Settings.shared.bpmUpperValue + 20))

                // Phase from the wall clock rather than an accumulator, so a restarted stream
                // or a spell in the background resumes at the right point instead of drifting.
                let phase = Date().timeIntervalSince(start)
                    .truncatingRemainder(dividingBy: period) / period
                let triangle = phase < 0.5 ? phase * 2 : (1 - phase) * 2

                onBeat(UInt8(clamping: Int((low + (high - low) * triangle).rounded())))
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
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
