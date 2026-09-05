import Foundation
import Combine

class Settings: ObservableObject {
    static let shared = Settings()

    // Seconds
    static let alertIntervalOptions = [1, 3, 5, 10]
    static let outOfRangeForOptions = [0, 5, 10, 30, 60, 300, 600]

    // Seconds, plus a sentinel: hold alerts until BPM first enters the range
    static let initialDelayUntilInRange = -1
    static let initialDelayOptions = [0, initialDelayUntilInRange, 60, 300, 600, 900]
    static let initialDelayLabels = [0: "off", initialDelayUntilInRange: "until in range"]

    /// Tracking sessions a new user gets before the paywall.
    static let freeSessionLimit = 5

    /// A session only counts, and only earns a review prompt, once it passes this.
    static let sessionMinDuration: TimeInterval = 60

    @Published var bpmLowerValue: Int
    @Published var bpmUpperValue: Int
    @Published var volume: Int
    @Published var vibrate: Bool
    @Published var alertInterval: Int
    @Published var outOfRangeFor: Int
    @Published var initialDelay: Int

    /// Entitled, whether bought or granted for being an existing user.
    @Published private(set) var unlimitedAccess: Bool
    @Published private(set) var trackedSessions: Int

    /// Reviewer demo mode, unlocked from ConnectView. In memory only — never persisted, so it
    /// dies with the process and a real user who trips it loses nothing by relaunching.
    @Published var demoMode = false

    /// Shadow entitlement for demo mode. Lets the paywall be reached and re-tested without
    /// ever reading, granting or clearing the real, write-once `unlimitedAccess`.
    @Published var demoUnlocked = false

    /// The entitlement the UI should believe. Demo mode substitutes its own, so the paywall
    /// shows on the first Start even on a device that already owns the product.
    var entitled: Bool { demoMode ? demoUnlocked : unlimitedAccess }

    /// Whether tracking may start: entitled, or still has free sessions left. Demo mode has no
    /// free sessions, so the reviewer meets the paywall immediately.
    var canStartSession: Bool {
        entitled || (!demoMode && trackedSessions < Settings.freeSessionLimit)
    }

    /// Free sessions still on offer, for the Start button's label. Zero once they are used up,
    /// for an entitled user who should not be told about free sessions at all, and in demo
    /// mode — where `canStartSession` grants none, so advertising them would be a lie.
    var freeSessionsLeft: Int {
        (entitled || demoMode) ? 0 : max(0, Settings.freeSessionLimit - trackedSessions)
    }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Must stay above the sinks at the bottom of this init: they publish immediately on
        // subscribe, so a moment later every key exists and the evidence of seniority is gone.
        Settings.resolveEntitlementIfNeeded()

        // Load from UserDefaults
        self.bpmLowerValue = UserDefaults.standard.object(forKey: "bpmLowerValue") as? Int ?? 110
        self.bpmUpperValue = UserDefaults.standard.object(forKey: "bpmUpperValue") as? Int ?? 140
        self.volume = UserDefaults.standard.object(forKey: "volume") as? Int ?? 90
        self.vibrate = UserDefaults.standard.object(forKey: "vibrate") as? Bool ?? false
        self.alertInterval = UserDefaults.standard.object(forKey: "alertInterval") as? Int ?? 1
        self.outOfRangeFor = UserDefaults.standard.object(forKey: "outOfRangeFor") as? Int ?? 0
        self.initialDelay = UserDefaults.standard.object(forKey: "initialDelay") as? Int ?? 0
        self.unlimitedAccess = UserDefaults.standard.bool(forKey: "unlimitedAccess")
        self.trackedSessions = UserDefaults.standard.integer(forKey: "trackedSessions")

        SoundManager.shared.start()
        SoundManager.shared.volume = Float(self.volume) / 100
        VibrationManager.shared.vibrate = self.vibrate
        
        // Automatically save to UserDefaults when values change
        $bpmLowerValue
            .sink { UserDefaults.standard.set($0, forKey: "bpmLowerValue") }
            .store(in: &cancellables)
        
        $bpmUpperValue
            .sink { UserDefaults.standard.set($0, forKey: "bpmUpperValue") }
            .store(in: &cancellables)

        $volume
            .sink {
                SoundManager.shared.volume = Float($0) / 100
                UserDefaults.standard.set($0, forKey: "volume")
            }
            .store(in: &cancellables)

        $vibrate
            .sink {
                VibrationManager.shared.vibrate = $0
                UserDefaults.standard.set($0, forKey: "vibrate")
            }
            .store(in: &cancellables)

        $alertInterval
            .sink { UserDefaults.standard.set($0, forKey: "alertInterval") }
            .store(in: &cancellables)

        $outOfRangeFor
            .sink { UserDefaults.standard.set($0, forKey: "outOfRangeFor") }
            .store(in: &cancellables)

        $initialDelay
            .sink { UserDefaults.standard.set($0, forKey: "initialDelay") }
            .store(in: &cancellables)

        $trackedSessions
            .sink { UserDefaults.standard.set($0, forKey: "trackedSessions") }
            .store(in: &cancellables)
    }

    /// Only ever set to true: a grandfathered user has no App Store purchase, so a
    /// "no purchase found" restore must never revoke it.
    func grantUnlimitedAccess() {
        // Set first: the guard below returns early on a device that already owns the product,
        // and the demo flow still needs its own flag flipped.
        if demoMode { demoUnlocked = true }
        guard !unlimitedAccess else { return }
        UserDefaults.standard.set(true, forKey: "unlimitedAccess")
        unlimitedAccess = true
    }

    /// Counts one completed session. Stops at the free limit, and never counts for an
    /// entitled user.
    func countTrackedSession() {
        guard !unlimitedAccess, trackedSessions < Settings.freeSessionLimit else { return }
        trackedSessions += 1
    }

    /// Settings the released 2.0.1 wrote. Their presence means the user was here before the
    /// paywall. Frozen on purpose: a setting added later is not evidence of seniority.
    private static let legacyKeys = ["bpmLowerValue", "bpmUpperValue", "volume", "vibrate"]

    /// Grants unlimited access to everyone who was already using the app when the paywall
    /// shipped. Latched, so a later launch — by which point these keys always exist — cannot
    /// re-decide. Idempotent, and safe to call from anywhere, but it MUST run before anything
    /// writes a settings key.
    static func resolveEntitlementIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "entitlementResolved") else { return }
        if legacyKeys.contains(where: { defaults.object(forKey: $0) != nil }) {
            defaults.set(true, forKey: "unlimitedAccess")
        }
        defaults.set(true, forKey: "entitlementResolved")
    }
}
