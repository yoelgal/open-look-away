import XCTest
@testable import OpenLookAway

@MainActor
final class BreakEngineTests: XCTestCase {
    func testDefaults() {
        let s = AppSettings()
        XCTAssertEqual(s.focusMinutes, 20)
        XCTAssertEqual(s.shortBreakSeconds, 20)
        XCTAssertEqual(s.longBreakMinutes, 5)
        XCTAssertEqual(s.longBreakEvery, 3)
        XCTAssertEqual(s.beastPushUps, 10)
        XCTAssertFalse(s.beastModeEnabled)
    }

    func testFocusedTimeIgnoresPause() {
        let e = BreakEngine(settings: AppSettings())
        e.tick(now: Date(), paused: false, reason: nil, step: 10)
        XCTAssertEqual(e.focusedSeconds, 10)
        e.tick(now: Date(), paused: true, reason: "Typing", step: 10)
        XCTAssertEqual(e.focusedSeconds, 10)
        XCTAssertEqual(e.phase, .paused)
    }

    func testHeadsUpThenBreak() {
        var s = AppSettings()
        s.focusMinutes = 2
        let e = BreakEngine(settings: s)
        e.tick(now: Date(), paused: false, reason: nil, step: 61)
        XCTAssertEqual(e.phase, .headsUp)
        e.tick(now: Date(), paused: false, reason: nil, step: 52)
        XCTAssertEqual(e.phase, .cursorCountdown)
        e.tick(now: Date(), paused: false, reason: nil, step: 8)
        XCTAssertEqual(e.phase, .breaking)
        XCTAssertEqual(e.breakKind, .short)
        XCTAssertEqual(e.remainingBreak, 20)
    }

    func testLongEveryThird() {
        var s = AppSettings()
        s.focusMinutes = 1
        let e = BreakEngine(settings: s)
        for i in 1...3 {
            e.startBreakNow()
            XCTAssertEqual(e.breakKind, i == 3 ? .long : .short, "break \(i)")
            e.endBreak()
        }
    }

    func testOfficeHoursIdle() {
        var s = AppSettings()
        s.officeHoursEnabled = true
        s.officeStartHour = 9
        s.officeEndHour = 10
        s.officeWeekdaysOnly = false
        let e = BreakEngine(settings: s)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let now = cal.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 15))!
        e.tick(now: now, paused: false, reason: nil)
        XCTAssertEqual(e.phase, .idle)
    }

    func testHardcoreCannotSkip() {
        var s = AppSettings()
        s.skipStyle = .hardcore
        let e = BreakEngine(settings: s)
        e.startBreakNow()
        XCTAssertFalse(e.skipBreak())
        XCTAssertEqual(e.phase, .breaking)
    }

    func testCasualCanSkip() {
        var s = AppSettings()
        s.skipStyle = .casual
        let e = BreakEngine(settings: s)
        e.startBreakNow()
        XCTAssertTrue(e.skipBreak())
        XCTAssertEqual(e.phase, .focusing)
    }

    func testSnoozeCap() {
        var s = AppSettings()
        s.snoozesPerDay = 1
        let e = BreakEngine(settings: s)
        XCTAssertTrue(e.snooze(minutes: 1))
        XCTAssertFalse(e.snooze(minutes: 1))
    }
}

final class OfficeHoursTests: XCTestCase {
    func testOvernightWindow() {
        var s = AppSettings()
        s.officeHoursEnabled = true
        s.officeStartHour = 22
        s.officeEndHour = 2
        s.officeWeekdaysOnly = false
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let inside = cal.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 23))!
        let outside = cal.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 12))!
        XCTAssertTrue(OfficeHours.contains(inside, s, calendar: cal))
        XCTAssertFalse(OfficeHours.contains(outside, s, calendar: cal))
    }
}

final class SkipLadderTests: XCTestCase {
    func testBalancedDelay() {
        let start = Date()
        let unlock = SkipLadder.unlockDate(style: .balanced, startedAt: start)!
        XCTAssertFalse(SkipLadder.canSkip(style: .balanced, now: start, unlockedAt: unlock, inBreak: true))
        XCTAssertTrue(SkipLadder.canSkip(style: .balanced, now: unlock, unlockedAt: unlock, inBreak: true))
    }
}
