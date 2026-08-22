import AppKit
import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    let engine: BreakEngine
    let pause = SmartPause()
    let overlays = OverlayController()

    private var timer: AnyCancellable?
    private var headsUp: HeadsUpController?
    private var cursor: CursorCountdownController?
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.engine = BreakEngine()
        overlays.onSkip = { [weak self] in self?.skipBreak() }
        overlays.onDone = { [weak self] in self?.finishBreak() }
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
        var signal = pause.poll(settings: engine.settings)
        if engine.phase == .breaking || engine.phase == .headsUp || engine.phase == .cursorCountdown {
            if signal.reason == "Idle" || signal.reason == "Typing" {
                signal = PauseSignal(paused: false, reason: nil)
            }
        }
        engine.tick(now: now, paused: signal.paused, reason: signal.reason)
        syncChrome()
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
