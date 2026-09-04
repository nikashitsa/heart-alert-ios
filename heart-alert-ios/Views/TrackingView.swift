import StoreKit
import SwiftUI

struct TrackingView: View {
    var onCancel: () -> Void = {}

    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @Environment(\.requestReview) private var requestReview

    @StateObject private var settings = Settings.shared

    @State private var state: TrackingState = .good
    @State private var isPulsing = false
    @State private var bpm: Int = -1
    @State private var prevConnectionState: DeviceConnectionState = .connected("")

    // Timestamps, nil when they haven't happened yet
    @State private var lastTriggerTime: Date? = nil
    // Start of the current uninterrupted out-of-range stretch, nil while in range
    @State private var outOfRangeSince: Date? = nil
    // Whether the stretch has already lasted long enough for alerts to start
    @State private var alerting = false
    // Alerts are held back at the start of a session until HR first reaches the
    // range, or until the initial delay times out, whichever comes first
    @State private var initialDelayPassed = false
    @State private var trackingStartedAt = Date()
    /// Whether this session ran long enough to count, and to be worth a review prompt
    @State private var sessionRan = false

    private var initialDelayActive: Bool {
        if initialDelayPassed { return false }
        // "Until in range" never times out, it only ends once HR reaches the range
        if settings.initialDelay == Settings.initialDelayUntilInRange { return true }
        return Date().timeIntervalSince(trackingStartedAt) < TimeInterval(settings.initialDelay)
    }
    private var outOfRangeForInterval: TimeInterval { TimeInterval(settings.outOfRangeFor) } // sec
    private var throttleInterval: TimeInterval { TimeInterval(settings.alertInterval) - 0.31 } // sec
    private var alertColor: Color { alerting ? Colors.red : Colors.white }

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
                    // Only worth asking after a session that actually ran.
                    if sessionRan { requestReview() }
                }) {
                    Text("Stop").setFontStyle(Fonts.textMdBold)
                }.buttonStyle(PrimaryButton())
            }
            .foregroundColor(Colors.white)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Counts the session at the one minute mark rather than on Stop, so quitting
        // mid-session cannot dodge it. Cancelled when this view goes away, which is what
        // keeps a shorter session from counting at all.
        .task {
            try? await Task.sleep(nanoseconds: UInt64(Settings.sessionMinDuration) * 1_000_000_000)
            // try? swallows the cancellation, so it has to be checked by hand
            guard !Task.isCancelled,
                  Date().timeIntervalSince(trackingStartedAt) >= Settings.sessionMinDuration
            else { return }
            sessionRan = true
            settings.countTrackedSession()
        }
    }

    private func bpmView() -> some View {
        VStack(spacing: 20) {
            switch bluetoothManager.deviceConnectionState {
            case .disconnected:
                Text("Disconnected")
                    .setFontStyle(Fonts.textLg)
                    .task { await playRepeatedly(.disconnected) }
            case .connecting:
                Text("Reconnecting...")
                    .setFontStyle(Fonts.textLg)
                    .task { await playRepeatedly(.reconnecting) }
            case .connected:
                if bluetoothManager.hrFeature.isSupported {
                    bpmReadout()
                    alertStatus()
                } else {
                    Text("Reconnecting...").setFontStyle(Fonts.textLg)
                }
            }
        }
    }

    /// The big BPM number with the beating heart next to it.
    private func bpmReadout() -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text(bpm > -1 ? "\(bpm)" : "--")
                .setFontStyle(Fonts.text2XlBold)
                .monospacedDigit()
                .frame(maxHeight: 80)
                .foregroundColor(alertColor)
            VStack(alignment: .center, spacing: 12) {
                Image("Heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 32.0)
                    .scaleEffect(isPulsing ? 1.2 : 1.0, anchor: .center)
                    .onAppear { startPulse() }
                    .onChange(of: state) { _ in startPulse() }
                    .contentTransition(.identity)
                Text("BPM")
                    .setFontStyle(Fonts.textLg)
                    .foregroundColor(alertColor)
            }
        }
        .onAppear {
            if case .disconnected = prevConnectionState {
                SoundManager.shared.play(.connected)
            }
            bluetoothManager.hrStreamStart(onHeartRate)
        }
    }

    /// The line under the BPM number. While alerts are held back it shows what is
    /// being waited on, the initial delay first, then the wait for HR to stay out
    /// of range. Otherwise it shows the state itself: "Good" while in range, or
    /// what is wrong once alerts start, but only once a first reading has arrived.
    /// The fixed height keeps the screen from jumping as it switches between them.
    private func alertStatus() -> some View {
        Group {
            if initialDelayActive {
                if settings.initialDelay > 0 {
                    InitialDelayCountdown(since: trackingStartedAt, duration: TimeInterval(settings.initialDelay))
                } else {
                    Text("Initial delay until in range").setFontStyle(Fonts.textLg)
                }
            } else if !alerting, let since = outOfRangeSince, outOfRangeForInterval > 0 {
                AlertCountdown(since: since, duration: outOfRangeForInterval)
            } else if bpm > -1 {
                Text(state.heartBeatDescription).setFontStyle(Fonts.textLg)
            }
        }
        .frame(height: 30)
    }

    /// Called for every heart rate sample the strap sends, about once a second.
    private func onHeartRate(_ hr: UInt8) {
        bpm = Int(hr)
        let prevState = state
        state = TrackingState.of(bpm, settings.bpmLowerValue, settings.bpmUpperValue)
        let now = Date()

        // Back in range. Announce the recovery only if we were really alerting.
        if state == .good {
            outOfRangeSince = nil
            lastTriggerTime = nil
            // Only "until in range" ends here, a timed delay runs to completion
            if settings.initialDelay == Settings.initialDelayUntilInRange {
                initialDelayPassed = true
            }
            if alerting {
                alerting = false
                SoundManager.shared.play(state.soundState)
            }
            return
        }

        // Out of range. Keep timing the stretch even while alerts are held back.
        let since = outOfRangeSince ?? now
        outOfRangeSince = since

        // Hold everything back while the initial delay is still running.
        if initialDelayActive { return }

        // Stay quiet until HR has been out of range long enough.
        if now.timeIntervalSince(since) < outOfRangeForInterval { return }

        // Say what is wrong when alerts start, and again on a too low <-> too high flip.
        if !alerting || state != prevState {
            alerting = true
            SoundManager.shared.play(state.soundState)
        }

        // Repeat the beep and the vibration at the chosen interval.
        if let lastTrigger = lastTriggerTime, now.timeIntervalSince(lastTrigger) <= throttleInterval {
            return
        }
        lastTriggerTime = now
        if let sound = state.sound {
            SoundManager.shared.play(sound)
        }
        VibrationManager.shared.play(state)
    }

    private func playRepeatedly(_ sound: SoundType) async {
        prevConnectionState = .disconnected("")
        while !Task.isCancelled {
            SoundManager.shared.play(sound)
            try? await Task.sleep(nanoseconds: 5_000_000_000)
        }
    }

    private func startPulse() {
        isPulsing = false
        withAnimation(
            .easeOut(duration: state.heartBeatDuration).repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }
}

/// Counts down the time left of the initial delay, during which alerts are held back.
/// `since` is when tracking started, `duration` the delay in seconds.
struct InitialDelayCountdown: View {
    let since: Date
    let duration: TimeInterval

    var body: some View {
        // faster than once a second, so the displayed second never lags behind
        TimelineView(.periodic(from: since, by: 0.2)) { context in
            let remaining = Int(max(0, duration - context.date.timeIntervalSince(since)))
            Text(String(format: "Initial delay %02d:%02d", remaining / 60, remaining % 60))
                .setFontStyle(Fonts.textLg).monospacedDigit()
        }
    }
}

/// Fills up as the current out-of-range stretch approaches `duration` seconds, at
/// which point alerts start. `since` is the start of the stretch.
struct AlertCountdown: View {
    let since: Date
    let duration: TimeInterval

    var body: some View {
        // one step per ~1% of the wait, so a 10 min countdown isn't redrawn 20x a second
        TimelineView(.periodic(from: since, by: min(max(duration / 100, 0.05), 1))) { context in
            let progress = min(max(context.date.timeIntervalSince(since) / duration, 0), 1)
            ZStack {
                Circle().stroke(Colors.white, lineWidth: 2)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Colors.red, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 20, height: 20)
        }
    }
}

#Preview {
    TrackingView().environmentObject(BluetoothManager())
}
