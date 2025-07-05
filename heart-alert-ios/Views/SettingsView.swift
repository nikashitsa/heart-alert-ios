import SwiftUI

struct SettingsView: View {
    var onSuccess: () -> Void = {}

    @EnvironmentObject private var bluetoothManager: BluetoothManager
    
    @State private var showDevicePicker = false
    @State private var showBpmMaxPicker = false
    @State private var showBpmMinPicker = false
    
    @StateObject private var settings = Settings.shared
    
    var volumeBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(settings.volume) },
            set: {
                SoundManager.shared.play(.lowBeep)
                settings.volume = Int($0)
            }
        )
    }
    
    var vibrateBinding: Binding<Bool> {
        Binding<Bool>(
            get: { settings.vibrate },
            set: {
                settings.vibrate = $0
            }
        )
    }
    
    var body: some View {
        ZStack {
            Colors.black.ignoresSafeArea()
            VStack {                
                ScrollView {
                    VStack (alignment: .leading, spacing: 40) {
                        Text("Settings").setFontStyle(Fonts.textXlBold)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Heart rate").setFontStyle(Fonts.textLgBold)
                            VStack (spacing: 0) {
                                HStack {
                                    Text("Min").setFontStyle(Fonts.textMd)
                                    Spacer()
                                    Button(action: {
                                        showBpmMinPicker = true
                                    }) {
                                        Text("\(settings.bpmLowerValue) BPM").setFontStyle(Fonts.textMd)
                                        Image(systemName: "chevron.right")
                                    }
                                    .sheet(
                                        isPresented: $showBpmMinPicker
                                    ) {
                                        BpmPickerView(
                                            range: 40...settings.bpmUpperValue,
                                            title: "Choose min BPM",
                                            selectedBpm: settings.bpmLowerValue
                                        ) { bpm in
                                            settings.bpmLowerValue = bpm
                                        }.presentationDetents([.medium])
                                    }
                                }.frame(height: 40)
                                HStack {
                                    Text("Max").setFontStyle(Fonts.textMd)
                                    Spacer()
                                    Button(action: {
                                        showBpmMaxPicker = true
                                    }) {
                                        Text("\(settings.bpmUpperValue) BPM").setFontStyle(Fonts.textMd)
                                        Image(systemName: "chevron.right")
                                    }
                                    .sheet(
                                        isPresented: $showBpmMaxPicker
                                    ) {
                                        BpmPickerView(
                                            range: settings.bpmLowerValue...240,
                                            title: "Choose max BPM",
                                            selectedBpm: settings.bpmUpperValue
                                        ) { bpm in
                                            settings.bpmUpperValue = bpm
                                        }.presentationDetents([.medium])
                                    }
                                }.frame(height: 40)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Alert").setFontStyle(Fonts.textLgBold)
                            VStack (spacing: 4) {
                                Slider(
                                    value: volumeBinding,
                                    in: 0...100,
                                    label: {},
                                    minimumValueLabel: {
                                        Image(systemName: "speaker.fill")
                                    },
                                    maximumValueLabel: {
                                        Image(systemName: "speaker.3.fill")
                                    }
                                )
                                .frame(height: 40)
                                .accentColor(Colors.red)
                                
                                HStack {
                                    Toggle(isOn: vibrateBinding) {
                                        Text("Vibration").setFontStyle(Fonts.textMd)
                                    }.tint(Colors.red)
                                }.frame(height: 40)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Connection").setFontStyle(Fonts.textLgBold)
                            VStack (spacing: 0) {
                                HStack {
                                    Text("Device").setFontStyle(Fonts.textMd)
                                    Spacer()
                                    Button(action: {
                                        showDevicePicker = true
                                    }) {
                                        Text(bluetoothManager.deviceName).setFontStyle(Fonts.textMd)
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .frame(height: 40)
                                .sheet(
                                    isPresented: $showDevicePicker
                                ) {
                                    DevicePickerView()
                                        .presentationDetents([.medium])
                                }
                                if bluetoothManager.batteryStatusFeature.isSupported {
                                    HStack {
                                        Text("Battery").setFontStyle(Fonts.textMd)
                                        Spacer()
                                        Text("\(bluetoothManager.batteryStatusFeature.batteryLevel)%").setFontStyle(Fonts.textMd)
                                    }.frame(height: 40)
                                }
                            }
                        }
                    }.padding()
                }.scrollBounceBehavior(.basedOnSize, axes: [.vertical])
                
                Button(action: {
                    onSuccess()
                }) {
                    Text("Start").setFontStyle(Fonts.textMdBold)
                }
                .buttonStyle(PrimaryButton())
                .padding()
            }.foregroundColor(Colors.white)
        }
    }
}

#Preview {
    SettingsView().environmentObject(BluetoothManager())
}
