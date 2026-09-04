import SwiftUI

struct SettingsView: View {
    var onSuccess: () -> Void = {}

    @EnvironmentObject private var bluetoothManager: BluetoothManager

    @State private var showDevicePicker = false
    @State private var showBpmMaxPicker = false
    @State private var showBpmMinPicker = false
    @State private var showIntervalPicker = false
    @State private var showOutOfRangeForPicker = false
    @State private var showInitialDelayPicker = false
    @State private var showAdvanced = false
    @State private var showPaywall = false

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
                                            range: 30...settings.bpmUpperValue,
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
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation { showAdvanced.toggle() }
                                    }) {
                                        HStack(spacing: 8) {
                                            Text("Advanced").setFontStyle(Fonts.textMd)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .rotationEffect(.degrees(showAdvanced ? 90 : 0))
                                        }
                                        .frame(height: 40)
                                    }

                                    if showAdvanced {
                                        VStack (spacing: 0) {
                                            HStack {
                                                Toggle(isOn: vibrateBinding) {
                                                    Text("Vibration").setFontStyle(Fonts.textMd)
                                                }.tint(Colors.red)
                                            }.frame(height: 40)

                                            HStack {
                                                Text("Interval").setFontStyle(Fonts.textMd)
                                                Spacer()
                                                Button(action: {
                                                    showIntervalPicker = true
                                                }) {
                                                    Text(IntervalPickerView.label(settings.alertInterval)).setFontStyle(Fonts.textMd)
                                                    Image(systemName: "chevron.right")
                                                }
                                                .sheet(
                                                    isPresented: $showIntervalPicker
                                                ) {
                                                    IntervalPickerView(
                                                        options: Settings.alertIntervalOptions,
                                                        title: "Choose alert interval",
                                                        selectedInterval: settings.alertInterval
                                                    ) { interval in
                                                        settings.alertInterval = interval
                                                    }.presentationDetents([.medium])
                                                }
                                            }.frame(height: 40)

                                            HStack {
                                                Text("Out of range for").setFontStyle(Fonts.textMd)
                                                Spacer()
                                                Button(action: {
                                                    showOutOfRangeForPicker = true
                                                }) {
                                                    Text(IntervalPickerView.label(settings.outOfRangeFor)).setFontStyle(Fonts.textMd)
                                                    Image(systemName: "chevron.right")
                                                }
                                                .sheet(
                                                    isPresented: $showOutOfRangeForPicker
                                                ) {
                                                    IntervalPickerView(
                                                        options: Settings.outOfRangeForOptions,
                                                        title: "Alert after out of range for",
                                                        selectedInterval: settings.outOfRangeFor
                                                    ) { seconds in
                                                        settings.outOfRangeFor = seconds
                                                    }.presentationDetents([.medium])
                                                }
                                            }.frame(height: 40)

                                            HStack {
                                                Text("Initial delay").setFontStyle(Fonts.textMd)
                                                Spacer()
                                                Button(action: {
                                                    showInitialDelayPicker = true
                                                }) {
                                                    Text(IntervalPickerView.label(settings.initialDelay, Settings.initialDelayLabels)).setFontStyle(Fonts.textMd)
                                                    Image(systemName: "chevron.right")
                                                }
                                                .sheet(
                                                    isPresented: $showInitialDelayPicker
                                                ) {
                                                    IntervalPickerView(
                                                        options: Settings.initialDelayOptions,
                                                        labels: Settings.initialDelayLabels,
                                                        title: "Choose initial delay",
                                                        selectedInterval: settings.initialDelay
                                                    ) { seconds in
                                                        settings.initialDelay = seconds
                                                    }.presentationDetents([.medium])
                                                }
                                            }.frame(height: 40)
                                        }
                                    }
                                }
                                
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
                    if settings.canStartSession {
                        onSuccess()
                    } else {
                        showPaywall = true
                    }
                }) {
                    // A user who never had free sessions to spend, or who has used them all,
                    // just gets "Start".
                    let freeLeft = settings.freeSessionsLeft
                    Text(freeLeft > 0 ? "Start for free (\(freeLeft))" : "Start")
                        .setFontStyle(Fonts.textMdBold)
                }
                .buttonStyle(PrimaryButton())
                .padding()
                .sheet(
                    isPresented: $showPaywall,
                    onDismiss: {
                        // Covers a swipe-away after the purchase landed; Continue takes the
                        // same path.
                        if settings.canStartSession { onSuccess() }
                    }
                ) {
                    PaywallView()
                        .presentationDetents([.medium])
                }
            }.foregroundColor(Colors.white)
        }
    }
}

#Preview {
    SettingsView().environmentObject(BluetoothManager())
}
