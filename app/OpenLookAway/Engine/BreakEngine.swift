import Foundation

@MainActor
final class BreakEngine: ObservableObject {
    @Published var settings: AppSettings {
        didSet { settings.save(defaults: defaults) }
    }
    @Published private(set) var phase: Phase = .focusing
    @Published private(set) var breakKind: BreakKind = .short
    @Published private(set) var focusedSeconds: TimeInterval = 0
    @Published private(set) var remainingFocus: TimeInterval
    @Published private(set) var remainingBreak: TimeInterval = 0
    @Published private(set) var completedShorts: Int = 0
    @Published private(set) var snoozesUsedToday: Int = 0
    @Published private(set) var lastPauseReason: String?
    @Published private(set) var skipUnlockedAt: Date?
    @Published var statsFocusSecondsToday: TimeInterval = 0
    @Published var statsBreaksToday: Int = 0
    var armed: Bool = true

    private var snoozeDay: Date?
    private let defaults: UserDefaults

    init(settings: AppSettings = .load(), defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = settings
        self.remainingFocus = settings.focusDuration
    }

    var isBeast: Bool { settings.beastModeEnabled }
    var upcomingKind: BreakKind {
        ((completedShorts + 1) % settings.longBreakEvery == 0) ? .long : .short
    }

    func tick(now: Date, paused: Bool, reason: String?, step: TimeInterval = 1) {
        guard armed else { return }
        rollSnoozeDay(now)
        if !OfficeHours.contains(now, settings) {
            phase = .idle
            lastPauseReason = "Outside office hours"
            return
        }
        if phase == .idle {
            phase = .focusing
            lastPauseReason = nil
        }
        switch phase {
        case .idle:
            break
        case .focusing, .headsUp, .cursorCountdown:
            if paused {
                phase = .paused
                lastPauseReason = reason
                return
            }
            focusedSeconds += step
            statsFocusSecondsToday += step
            remainingFocus = max(0, settings.focusDuration - focusedSeconds)
            if remainingFocus <= 0 {
                beginBreak(now: now)
            } else if remainingFocus <= 8 {
                phase = .cursorCountdown
            } else if remainingFocus <= 60 {
                phase = .headsUp
            } else {
                phase = .focusing
            }
        case .paused:
            if !paused {
                phase = remainingFocus <= 8 ? .cursorCountdown : (remainingFocus <= 60 ? .headsUp : .focusing)
                lastPauseReason = nil
            } else {
                lastPauseReason = reason
            }
        case .breaking:
            remainingBreak = max(0, remainingBreak - step)
            if remainingBreak <= 0 { endBreak() }
        }
    }

    func startBreakNow() {
        beginBreak(now: Date())
    }

    func skipBreak() -> Bool {
        guard phase == .breaking || phase == .headsUp || phase == .cursorCountdown else { return false }
        guard SkipLadder.canSkip(style: settings.skipStyle, now: Date(), unlockedAt: skipUnlockedAt, inBreak: phase == .breaking) else {
            return false
        }
        endBreak()
        return true
    }

    func snooze(minutes: Int) -> Bool {
        rollSnoozeDay(Date())
        guard snoozesUsedToday < settings.snoozesPerDay else { return false }
        snoozesUsedToday += 1
        focusedSeconds = max(0, focusedSeconds - TimeInterval(minutes * 60))
        remainingFocus = max(0, settings.focusDuration - focusedSeconds)
        if phase == .breaking { remainingBreak = 0 }
        phase = remainingFocus <= 8 ? .cursorCountdown : (remainingFocus <= 60 ? .headsUp : .focusing)
        return true
    }

    func endBreak() {
        if phase == .breaking { statsBreaksToday += 1 }
        if phase == .breaking { completedShorts += 1 }
        focusedSeconds = 0
        remainingFocus = settings.focusDuration
        remainingBreak = 0
        skipUnlockedAt = nil
        phase = .focusing
    }

    func setBeast(_ on: Bool) {
        settings.beastModeEnabled = on
    }

    func updateSettings(_ next: AppSettings) {
        settings = next
        remainingFocus = max(0, settings.focusDuration - focusedSeconds)
    }
    func parkIdle() {
        phase = .idle
        lastPauseReason = nil
    }

    func unpark() {
        phase = .focusing
        lastPauseReason = nil
    }

    func debugJumpToHeadsUp() {
        focusedSeconds = max(0, settings.focusDuration - 10)
        remainingFocus = 10
        lastPauseReason = nil
        phase = .headsUp
    }

    private func beginBreak(now: Date) {
        breakKind = upcomingKind
        remainingBreak = breakKind == .long ? settings.longDuration : settings.shortDuration
        remainingFocus = 0
        phase = .breaking
        skipUnlockedAt = SkipLadder.unlockDate(style: settings.skipStyle, startedAt: now)
    }

    private func rollSnoozeDay(_ now: Date) {
        let day = Calendar.current.startOfDay(for: now)
        if snoozeDay != day {
            snoozeDay = day
            snoozesUsedToday = 0
            statsFocusSecondsToday = 0
            statsBreaksToday = 0
        }
    }
}
