import Foundation

/// A fixed app state for store screenshots, captured by `bundle exec fastlane screenshots`.
///
/// The lane launches the app in the Simulator with `-screenshot <scene>` (plus
/// `-AppleLanguages (<tag>)` and `-language <tag>` for the language) and snaps the screen.
/// The scene opens straight on its screen with a fake strap connected and fixed values, the
/// same ones the Android app's `ScreenshotTest` renders, so no Bluetooth or StoreKit is involved.
/// Debug builds only: in a release build `current` is always nil.
enum ScreenshotScene: String {
    case connect
    case settings
    case trackingLow = "tracking_low"
    case trackingGood = "tracking_good"
    case trackingHigh = "tracking_high"

    static let current: ScreenshotScene? = {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "screenshot").flatMap(ScreenshotScene.init)
        #else
        return nil
        #endif
    }()

    static let deviceName = "Polar H10 A203CC29"
    static let batteryLevel: UInt = 70
    static let hrMin = 110
    static let hrMax = 140

    var flow: AppFlow {
        switch self {
        case .connect: return .connect
        case .settings: return .settings
        case .trackingLow, .trackingGood, .trackingHigh: return .tracking
        }
    }

    /// The one reading the fake strap repeats.
    var bpm: UInt8 {
        switch self {
        case .trackingLow: return 64
        case .trackingHigh: return 145
        default: return 117
        }
    }

    /// Alerts raised on the first sample, so the out-of-range scenes show as alerting. Muted
    /// at the player rather than through the volume setting, whose slider is in the shot.
    /// These do persist on the Simulator: the settings' own sinks write them.
    func apply(to settings: Settings, bluetooth: BluetoothManager) {
        settings.bpmLowerValue = Self.hrMin
        settings.bpmUpperValue = Self.hrMax
        settings.outOfRangeFor = 0
        settings.initialDelay = 0
        settings.volume = 90
        settings.vibrate = false
        SoundManager.shared.volume = 0
        if self != .connect {
            bluetooth.screenshotConnect()
        }
    }
}
