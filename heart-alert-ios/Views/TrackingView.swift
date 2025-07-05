import StoreKit
import SwiftUI

struct TrackingView: View {
    var onCancel: () -> Void = {}
    
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @Environment(\.requestReview) private var requestReview
    
    @State private var state: TrackingState = .good
    @State private var isPulsing = false
    @State private var bpm: Int = -1
    
    @StateObject private var settings = Settings.shared
    
    @State private var lastTriggerTime: Date? = nil
    let throttleInterval: TimeInterval = 0.69 // sec
    @State private var prevConnectionState: DeviceConnectionState = .connected("")
    
    var body: some View {
        ZStack {
            Colors.black.ignoresSafeArea()
            VStack {
                HStack {
                    Text("Range \(settings.bpmLowerValue)-\(settings.bpmUpperValue) BPM").setFontStyle(Fonts.textMdBold)
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    bpmView()
                    Spacer()
                }
                
                Button(action: {
                    bluetoothManager.onlineStreamStop(feature: .hr)
                    onCancel()
                    requestReview()
                }) {
                    Text("Stop").setFontStyle(Fonts.textMdBold)
                }.buttonStyle(PrimaryButton())
            }
            .foregroundColor(Colors.white)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func bpmView() -> some View {
        VStack(spacing: 20) {
            switch bluetoothManager.deviceConnectionState {
            case .disconnected:
                Text("Disconnected")
                    .setFontStyle(Fonts.textLg)
                    .onAppear {
                        prevConnectionState = .disconnected("")
                        SoundManager.shared.play(.disconnected)
                    }
            case .connecting:
                Text("Reconnecting...")
                    .setFontStyle(Fonts.textLg)
                    .onAppear {
                        prevConnectionState = .disconnected("")
                        SoundManager.shared.play(.reconnecting)
                    }
            case .connected:
                if bluetoothManager.hrFeature.isSupported {
                    HStack(alignment: .bottom, spacing: 12) {
                        let bpmLabel = bpm > -1 ? "\(bpm)" : "--"
                        Text(bpmLabel)
                            .setFontStyle(Fonts.text2XlBold)
                            .frame(maxHeight: 80)
                            .foregroundColor(state.heartBeatColor)
                        VStack(alignment: .center, spacing: 12) {
                            Image("Heart")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 32.0)
                                .scaleEffect(isPulsing ? 1.2 : 1.0, anchor: .center)
                                .onAppear {
                                    startPulse()
                                }
                                .onChange(of: state) { _ in
                                    startPulse()
                                    SoundManager.shared.play(state.soundState)
                                }
                                .contentTransition(.identity)
                            Text("BPM")
                                .setFontStyle(Fonts.textLg)
                                .foregroundColor(state.heartBeatColor)
                        }.onAppear {
                            if case .disconnected = prevConnectionState {
                                SoundManager.shared.play(.connected)
                            }
                            bluetoothManager.hrStreamStart { hr in
                                bpm = Int(hr)
                                if bpm > settings.bpmUpperValue {
                                    state = .high
                                } else if bpm < settings.bpmLowerValue {
                                    state = .low
                                } else {
                                    state = .good
                                }
                                
                                let now = Date()
                                if let lastTime = lastTriggerTime,
                                   now.timeIntervalSince(lastTime) < throttleInterval {
                                    return
                                }
                                lastTriggerTime = now
                                
                                if let sound = state.sound {
                                    SoundManager.shared.play(sound)
                                }
                                VibrationManager.shared.play(state)
                            }
                        }
                    }
                    Text(state.heartBeatDescription).setFontStyle(Fonts.textLg)
                } else {
                    Text("Reconnecting...").setFontStyle(Fonts.textLg)
                }
            }
        }
    }
    
    func startPulse() {
        isPulsing = false
        withAnimation(
            .easeOut(duration: state.heartBeatDuration).repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }
}

#Preview {
    TrackingView().environmentObject(BluetoothManager())
}
