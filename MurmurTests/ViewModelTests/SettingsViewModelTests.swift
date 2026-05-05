import XCTest
import SwiftData
@testable import Murmur

@MainActor
final class SettingsViewModelTests: XCTestCase {
    /// Mutating `consentAlwaysRemind` through the VM must round-trip to
    /// `UserDefaults` (PRD §10). `ConsentReminderService` lives behind a
    /// computed property so a simple binding read/write covers Observation
    /// correctness too — if the storage path regressed, this would fail.
    func testConsentAlwaysRemindWritesUserDefaults() {
        let key = "consent.alwaysRemind"
        let prior = UserDefaults.standard.object(forKey: key)
        defer {
            if let prior {
                UserDefaults.standard.set(prior, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.standard.set(true, forKey: key)

        let services = ServiceContainer(modelContainer: MurmurStore.previewContainer())
        let vm = SettingsViewModel(services: services)
        XCTAssertTrue(vm.consentAlwaysRemind)

        vm.consentAlwaysRemind = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: key))
        XCTAssertFalse(services.consent.alwaysRemind)

        vm.consentAlwaysRemind = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: key))
        XCTAssertTrue(services.consent.alwaysRemind)
    }
}
