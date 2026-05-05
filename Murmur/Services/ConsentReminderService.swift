import Foundation
import Observation

/// Tracks consent-reminder preferences and the consent-education sheet state.
/// PRD §2.2 / §10: a per-recording reminder, with a one-time education
/// disclosure on the user's first call.
///
/// We deliberately avoid `@AppStorage` here. `@AppStorage` is a SwiftUI
/// property wrapper that participates in `View.body` invalidation; placed
/// inside an `@Observable` and marked `@ObservationIgnored`, it bypasses
/// Observation entirely, so any non-Toggle consumer (e.g. a banner gated on
/// `alwaysRemind`) will not re-render when the value flips. We back the
/// properties with `UserDefaults` directly and route reads/writes through
/// regular stored properties so the `@Observable` macro tracks them.
@MainActor
@Observable
final class ConsentReminderService {
    private static let alwaysRemindKey = "consent.alwaysRemind"
    private static let educationShownKey = "consent.educationShown"
    private static let lastReminderSeenAtKey = "consent.lastReminderSeenAt"

    private var _alwaysRemind: Bool
    private var _educationShown: Bool
    private var _lastReminderSeenAtRaw: Double

    init(defaults: UserDefaults = .standard) {
        // `register` so a fresh install honors the "remind by default" rule
        // without writing to disk.
        defaults.register(defaults: [
            Self.alwaysRemindKey: true,
            Self.educationShownKey: false,
            Self.lastReminderSeenAtKey: 0.0
        ])
        self._alwaysRemind = defaults.bool(forKey: Self.alwaysRemindKey)
        self._educationShown = defaults.bool(forKey: Self.educationShownKey)
        self._lastReminderSeenAtRaw = defaults.double(forKey: Self.lastReminderSeenAtKey)
    }

    var alwaysRemind: Bool {
        get { _alwaysRemind }
        set {
            _alwaysRemind = newValue
            UserDefaults.standard.set(newValue, forKey: Self.alwaysRemindKey)
        }
    }

    var educationShown: Bool {
        get { _educationShown }
        set {
            _educationShown = newValue
            UserDefaults.standard.set(newValue, forKey: Self.educationShownKey)
        }
    }

    var lastReminderSeenAt: Date {
        get { Date(timeIntervalSince1970: _lastReminderSeenAtRaw) }
        set {
            _lastReminderSeenAtRaw = newValue.timeIntervalSince1970
            UserDefaults.standard.set(_lastReminderSeenAtRaw, forKey: Self.lastReminderSeenAtKey)
        }
    }

    /// Whether to show the long consent education sheet before this recording.
    func shouldShowEducation(callsCount: Int) -> Bool {
        callsCount == 0 && !educationShown
    }

    /// Whether to show the lightweight banner reminder.
    func shouldShowBanner() -> Bool {
        guard alwaysRemind else { return false }
        // Don't pester within 60 seconds of the last sighting.
        return Date.now.timeIntervalSince(lastReminderSeenAt) > 60
    }

    func markEducationShown() {
        educationShown = true
        markBannerSeen()
    }

    func markBannerSeen() {
        lastReminderSeenAt = .now
    }
}
