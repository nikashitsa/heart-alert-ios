import SwiftUI
import PolarBleSdk

struct DevicePickerView: View {
    @State private var selectedDevice: DeviceInfo? = nil
    @State private var state: DevicePickerState = .searching
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    
    @State var timeoutTask: Task<Void, Never>? = nil
    
    private var sortedDevices: [DeviceInfo] {
        bluetoothManager.foundDevices.sorted { $0.rssi > $1.rssi }
    }
    
    var body: some View {
        VStack {
            if bluetoothManager.isBluetoothOn {
                switch state {
                case .searching:
                    if sortedDevices.isEmpty {
                        Text("Searching for devices...").setFontStyle(Fonts.textLgBold)
                        VStack {
                            ProgressView()
                        }.frame(maxHeight: .infinity)
                            .onAppear {
                                bluetoothManager.startDevicesSearch()
                                timeoutTask = Task {
                                    do {
                                        try await Task.sleep(nanoseconds: 10 * 1_000_000_000) // 10 sec
                                    } catch {
                                        if Task.isCancelled {
                                            return
                                        }
                                    }
                                    if sortedDevices.isEmpty {
                                        bluetoothManager.stopDevicesSearch()
                                        state = .notFound
                                    }
                                }
                            }
                    } else {
                        Text("Choose device").setFontStyle(Fonts.textLgBold)
                        VStack {
                            Picker("Devices", selection: $selectedDevice) {
                                ForEach(sortedDevices) { device in
                                    Text(device.name)
                                        .setFontStyle(Fonts.textMd)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .tag(device)
                                }
                            }
                            .pickerStyle(.wheel)
                        }.frame(maxHeight: .infinity)
                        Button(action: connect) {
                            Text("Choose").setFontStyle(Fonts.textMdBold)
                        }.buttonStyle(PrimaryButton())
                    }
                case .connecting:
                    Text("Connecting...").setFontStyle(Fonts.textLgBold)
                    VStack {
                        ProgressView()
                    }.frame(maxHeight: .infinity)
                case .notFound:
                    Text("Devices not found").setFontStyle(Fonts.textLgBold)
                    VStack {
                        Text("Make sure that you put it on and the battery level is good.")
                            .setFontStyleMultiline(Fonts.textMd)
                    }.frame(maxHeight: .infinity)
                    Button(action: {
                        state = .searching
                    }) {
                        Text("Try again").setFontStyle(Fonts.textMdBold)
                    }.buttonStyle(PrimaryButton())
                }
            } else {
                Text("Bluetooth is off").setFontStyle(Fonts.textLgBold)
                VStack {
                    Text("Please enable Bluetooth on your device to continue.")
                        .setFontStyleMultiline(Fonts.textMd)
                }.frame(maxHeight: .infinity)
            }
        }
        .onDisappear {
            bluetoothManager.stopDevicesSearch()
            if timeoutTask != nil {
                timeoutTask!.cancel()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func connect() {
        state = .connecting
        Task {
            if let selected = selectedDevice ?? sortedDevices.first {
                if case .connected(let address) = bluetoothManager.deviceConnectionState, address == selected.address.uuidString {
                    return dismiss()
                }
                bluetoothManager.disconnectFromDevice()
                for await state in bluetoothManager.$deviceConnectionState.values {
                    if case .disconnected = state {
                        break
                    }
                }
                bluetoothManager.updateSelectedDevice(address: selected.address.uuidString)
                bluetoothManager.connectToDevice()
                for await state in bluetoothManager.$deviceConnectionState.values {
                    if case .connected = state {
                        break
                    }
                }
                dismiss()
            }
        }
    }
}

enum DevicePickerState {
    case searching, connecting, notFound
}
