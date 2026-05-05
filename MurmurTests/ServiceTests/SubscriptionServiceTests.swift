import XCTest
@testable import Murmur

@MainActor
final class SubscriptionServiceTests: XCTestCase {
    func testFreeTierCapsAt3() async {
        let s = SubscriptionService()
        UserDefaults.standard.removeObject(forKey: "sub.monthlyUsed")
        UserDefaults.standard.removeObject(forKey: "sub.monthKey")
        XCTAssertTrue(s.canStartNewRecording())
        s.recordRecordingStart()
        s.recordRecordingStart()
        s.recordRecordingStart()
        XCTAssertFalse(s.canStartNewRecording())
    }

    func testPaidTiersAreUncapped() {
        var t: SubscriptionTier = .plus
        XCTAssertNil(t.monthlyRecordingLimit)
        t = .pro
        XCTAssertNil(t.monthlyRecordingLimit)
        t = .lifetimeFounder
        XCTAssertNil(t.monthlyRecordingLimit)
    }

    func testGatingMatrix() {
        XCTAssertFalse(SubscriptionTier.free.unlocksMindMap)
        XCTAssertTrue(SubscriptionTier.plus.unlocksMindMap)
        XCTAssertFalse(SubscriptionTier.plus.unlocksWhisperKit)
        XCTAssertTrue(SubscriptionTier.pro.unlocksWhisperKit)
        XCTAssertTrue(SubscriptionTier.lifetimeFounder.unlocksDiarization)
    }
}
