import AppKit
import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    let engine: BreakEngine
    let pause = SmartPause()
    let overlays = OverlayController()
    let defaults: UserDefaults

    private var timer: AnyCancellable?
    private var headsUp: HeadsUpController?
    private var cursor: CursorCountdownController?
    private var cancellables = Set<AnyCancellable>()

    var needsOnboarding: Bool { Onboarding.needsOnboarding(defaults: defaults) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let settings = AppSettings.load(defaults: defaults)
        self.engine = BreakEngine(settings: settings, defaults: defaults)
        overlays.onSkip = { [weak self] in self?.skipBreak() }
        overlays.onDone = { [weak self] in self?.finishBreak() }
        if Onboarding.needsOnboarding(defaults: defaults) {
            engine.armed = false
            engine.parkIdle()
        }
        engine.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.step(now: now)
            }
    }
    func step(now: Date = Date()) {
        guard engine.armed else { return }
        var signal = pause.poll(settings: engine.settings)
        if engine.phase == .breaking || engine.phase == .headsUp || engine.phase == .cursorCountdown {
            if signal.reason == "Idle" || signal.reason == "Typing" {
                signal = PauseSignal(paused: false, reason: nil)
            }
        }
        engine.tick(now: now, paused: signal.paused, reason: signal.reason)
        syncChrome()
    }

    func finishOnboarding(focusMinutes: Int, shortBreakSeconds: Int, accessibilityGranted: Bool) {
        _ = accessibilityGranted
        var next = engine.settings
        next.focusMinutes = focusMinutes
        next.shortBreakSeconds = shortBreakSeconds
        engine.updateSettings(next)
        Onboarding.markFinished(defaults: defaults)
        pause.retryTap()
        engine.armed = true
        engine.unpark()
    }

    func startBreakNow() {
        engine.startBreakNow()
        syncChrome()
    }

    func skipBreak() {
        _ = engine.skipBreak()
        syncChrome()
    }

    func finishBreak() {
        engine.endBreak()
        syncChrome()
    }

    func jumpToHeadsUp() {
        engine.debugJumpToHeadsUp()
        syncChrome()
    }

    private func syncChrome() {
        switch engine.phase {
        case .headsUp:
            if headsUp == nil { headsUp = HeadsUpController(store: self) }
            headsUp?.show()
            cursor?.hide()
            overlays.hide()
        case .cursorCountdown:
            headsUp?.hide()
            if cursor == nil { cursor = CursorCountdownController(store: self) }
            cursor?.show()
            overlays.hide()
        case .breaking:
            headsUp?.hide()
            cursor?.hide()
            overlays.show(store: self)
        default:
            headsUp?.hide()
            cursor?.hide()
            overlays.hide()
        }
    }
}
