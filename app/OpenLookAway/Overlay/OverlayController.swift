import AppKit
import CoreGraphics
import QuartzCore
import SwiftUI

@MainActor
final class OverlayController {
    var onSkip: () -> Void = {}
    var onDone: () -> Void = {}
    private var windows: [NSWindow] = []
    private var showingBeast: Bool?
    private var visible = false

    func show(store: SessionStore) {
        let beast = store.engine.settings.beastModeEnabled
        if windows.isEmpty || showingBeast != beast {
            build(store: store)
            visible = false
        }
        guard !visible else { return }
        visible = true
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        for w in windows {
            w.alphaValue = 0
            w.orderFrontRegardless()
        }
        if reduceMotion {
            for w in windows { w.alphaValue = 1 }
            return
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            for w in windows { w.animator().alphaValue = 1 }
        }
    }

    func hide() {
        guard visible || !windows.isEmpty else { return }
        visible = false
        let closing = windows
        windows.removeAll()
        showingBeast = nil
        let tearDown = {
            for w in closing { w.discardHostedContent() }
        }
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            tearDown()
            return
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            ctx.completionHandler = tearDown
            for w in closing { w.animator().alphaValue = 0 }
        }
    }

    private func build(store: SessionStore) {
        for w in windows { w.discardHostedContent() }
        windows.removeAll()
        showingBeast = store.engine.settings.beastModeEnabled
        let shield = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        for screen in NSScreen.screens {
            let win = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            win.setFrame(screen.frame, display: true)
            win.isOpaque = true
            win.backgroundColor = .black
            win.level = shield
            win.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .stationary,
                .ignoresCycle
            ]
            win.hidesOnDeactivate = false
            win.ignoresMouseEvents = false
            win.hasShadow = false
            win.isReleasedWhenClosed = false
            win.animationBehavior = .none
            win.becomesKeyOnlyIfNeeded = true
            let root: AnyView = store.engine.settings.beastModeEnabled
                ? AnyView(BeastBreakView(
                    store: store,
                    onDone: { [weak self] in self?.onDone() },
                    onSkip: { [weak self] in self?.onSkip() }
                ))
                : AnyView(CalmBreakView(
                    store: store,
                    onSkip: { [weak self] in self?.onSkip() }
                ))
            let host = NSHostingController(rootView: root)
            host.view.frame = NSRect(origin: .zero, size: screen.frame.size)
            win.contentViewController = host
            windows.append(win)
        }
    }
}
