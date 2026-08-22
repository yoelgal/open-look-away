import XCTest
@testable import OpenLookAway

@MainActor
final class OnboardingTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        super.setUp()
        suite = "ola.test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func testNeedsOnboardingBlocksFocus() {
        let store = SessionStore(defaults: defaults)
        XCTAssertTrue(store.needsOnboarding)
        XCTAssertEqual(store.engine.phase, .idle)
        store.step(now: Date())
        store.step(now: Date())
        XCTAssertEqual(store.engine.focusedSeconds, 0)
        XCTAssertEqual(store.engine.phase, .idle)
    }

    func testExistingSettingsStillNeedOnboardingUntilStartNow() {
        var settings = AppSettings()
        settings.focusMinutes = 10
        settings.save(defaults: defaults)
        let store = SessionStore(defaults: defaults)
        XCTAssertTrue(store.needsOnboarding)
        XCTAssertEqual(store.engine.phase, .idle)
        store.step(now: Date())
        XCTAssertEqual(store.engine.focusedSeconds, 0)
    }

    func testFinishStartsFocusWithChosenPreset() {
        let store = SessionStore(defaults: defaults)
        store.finishOnboarding(
            focusMinutes: 15,
            shortBreakSeconds: 15,
            accessibilityGranted: true
        )
        XCTAssertEqual(store.engine.settings.focusMinutes, 15)
        XCTAssertEqual(store.engine.settings.shortBreakSeconds, 15)
        XCTAssertTrue(defaults.bool(forKey: Onboarding.flagKey))
        XCTAssertFalse(store.needsOnboarding)
        store.step(now: Date())
        XCTAssertGreaterThan(store.engine.focusedSeconds, 0)
        XCTAssertEqual(store.engine.phase, .focusing)
    }

    func testFinishWithoutAccessibility() {
        let store = SessionStore(defaults: defaults)
        store.finishOnboarding(
            focusMinutes: 20,
            shortBreakSeconds: 20,
            accessibilityGranted: false
        )
        XCTAssertFalse(store.needsOnboarding)
        XCTAssertTrue(defaults.bool(forKey: Onboarding.flagKey))
        store.step(now: Date())
        XCTAssertGreaterThan(store.engine.focusedSeconds, 0)
    }

    func testManualPauseStopsFocus() {
        let store = SessionStore(defaults: defaults)
        store.finishOnboarding(
            focusMinutes: 20,
            shortBreakSeconds: 20,
            accessibilityGranted: true
        )
        store.step(now: Date())
        let before = store.engine.focusedSeconds
        store.setManualPaused(true)
        store.step(now: Date())
        store.step(now: Date())
        XCTAssertEqual(store.engine.focusedSeconds, before)
        XCTAssertEqual(store.engine.phase, .paused)
        store.setManualPaused(false)
        store.step(now: Date())
        XCTAssertGreaterThan(store.engine.focusedSeconds, before)
    }
 }
