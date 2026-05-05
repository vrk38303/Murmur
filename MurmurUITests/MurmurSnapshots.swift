import XCTest

/// Drives the 6 App Store screenshots from SCREENSHOT_PLAN.md.
///
/// Run from CI via `bundle exec fastlane ios screenshots`. The Snapfile
/// targets iPhone 16 Pro Max only; the 6.9" frame auto-derives down to
/// 6.7"/6.5" classes inside App Store Connect.
///
/// The app is launched with `-MurmurSeedScreenshots` so MurmurDebugSeed
/// inserts hand-written CallEntities and a believable mind-map graph. Tests
/// here assume those seeds are present — they're not idempotent against an
/// empty store.
final class MurmurSnapshots: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-MurmurSeedScreenshots", "-MurmurUITestSkipOnboarding"]
        app.launch()
    }

    func test01Hero() {
        // Hero: live recording mid-conversation.
        let app = XCUIApplication()
        app.tabBars.buttons["tab.calls"].tap()
        app.buttons["calls.add"].tap()
        app.buttons["rec.sheet.start"].tap()
        // Let the timer/transcript breathe so the frame doesn't catch a 0:00.
        sleep(3)
        snapshot("01-Hero")
        app.buttons["rec.live.stop"].tap()
    }

    func test02Summary() {
        // Summary card on a finished call.
        let app = XCUIApplication()
        app.tabBars.buttons["tab.calls"].tap()
        app.cells["seed-call-1"].tap()
        app.buttons["detail.seg.summary"].tap()
        snapshot("02-Summary")
    }

    func test03MindMap() {
        // Mind map view (the differentiator).
        let app = XCUIApplication()
        app.tabBars.buttons["tab.map"].tap()
        // Wait for the force-directed layout to settle.
        sleep(2)
        snapshot("03-MindMap")
    }

    func test04OnboardingPrivacy() {
        // Onboarding privacy promise. Re-launch with onboarding forced visible.
        let app = XCUIApplication()
        app.terminate()
        app.launchArguments = ["-MurmurUITestForceOnboarding"]
        app.launch()
        snapshot("04-OnboardingPrivacy")
    }

    func test05CallsList() {
        // Calls list with content.
        let app = XCUIApplication()
        app.tabBars.buttons["tab.calls"].tap()
        snapshot("05-CallsList")
    }

    func test06SettingsPrivacy() {
        // Settings showing privacy controls.
        let app = XCUIApplication()
        app.tabBars.buttons["tab.settings"].tap()
        snapshot("06-SettingsPrivacy")
    }
}
