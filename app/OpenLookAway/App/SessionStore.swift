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
    var manualPaused = false
    var openSettings: () -> Void = {}
    var onStatusChange: () -> Void = {}
    var panelOpen = false
    @Published var availableUpdate: AvailableUpdate?

    private var clockUIVisible: Bool {
        if panelOpen { return true }
        switch engine.phase {
        case .headsUp, .cursorCountdown, .breaking: return true
        default: return false
        }
    }

    func startUpdateChecks() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let update = await UpdateCheck.run(
                .launch, defaults: self.defaults, currentVersion: AppInfo.version
            ).available {
                self.availableUpdate = update
            }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(UpdateCheck.interval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                if let update = await UpdateCheck.run(
                    .periodic, defaults: self.defaults, currentVersion: AppInfo.version
                ).available {
                    self.availableUpdate = update
                }
            }
        }
    }

    func checkForUpdates() async -> UpdateCheck.Outcome {
        let outcome = await UpdateCheck.run(
            .manual, defaults: defaults, currentVersion: AppInfo.version
        )
        if let update = outcome.available { availableUpdate = update }
        return outcome
    }

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
            guard let self, self.clockUIVisible else { return }
            self.objectWillChange.send()
        }.store(in: &cancellables)
        timer = Timer.publish(every: 1, tolerance: 0.25, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] now in
                self?.step(now: now)
            }
    }
    func step(now: Date = Date()) {
        guard engine.armed else { return }
        var signal = pause.poll(settings: engine.settings)
        if manualPaused {
            signal = PauseSignal(paused: true, reason: "Paused")
        }
        if engine.phase == .breaking || engine.phase == .headsUp || engine.phase == .cursorCountdown {
            if signal.reason == "Idle" || signal.reason == "Typing" {
                signal = PauseSignal(paused: false, reason: nil)
            }
        }
        if manualPaused, engine.phase == .breaking {
            engine.endBreak()
        }
        engine.tick(now: now, paused: signal.paused, reason: signal.reason)
        syncChrome()
        onStatusChange()
    }

    func setManualPaused(_ on: Bool) {
        manualPaused = on
        if on, engine.phase == .breaking {
            engine.endBreak()
        }
        objectWillChange.send()
        step()
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
        onStatusChange()
    }

    func startBreakNow() {
        engine.startBreakNow()
        syncChrome()
        onStatusChange()
    }

    func snooze(minutes: Int) {
        guard engine.snooze(minutes: minutes) else { return }
        syncChrome()
        onStatusChange()
    }

    func skipBreak() {
        _ = engine.skipBreak()
        syncChrome()
        onStatusChange()
    }

    func finishBreak() {
        engine.endBreak()
        syncChrome()
        onStatusChange()
    }

    func jumpToHeadsUp() {
        engine.debugJumpToHeadsUp()
        syncChrome()
        onStatusChange()
    }

    private func syncChrome() {
        switch engine.phase {
        case .headsUp:
            if headsUp == nil { headsUp = HeadsUpController(store: self) }
            headsUp?.show()
            cursor?.hide()
            cursor = nil
            overlays.hide()
        case .cursorCountdown:
            headsUp?.hide()
            headsUp = nil
            if cursor == nil { cursor = CursorCountdownController(store: self) }
            cursor?.show()
            overlays.hide()
        case .breaking:
            headsUp?.hide()
            headsUp = nil
            cursor?.hide()
            cursor = nil
            overlays.show(store: self)
        default:
            headsUp?.hide()
            headsUp = nil
            cursor?.hide()
            cursor = nil
            overlays.hide()
        }
    }
}
