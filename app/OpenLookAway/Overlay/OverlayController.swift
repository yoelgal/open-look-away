import AppKit
import SwiftUI

@MainActor
final class OverlayController {
    var onSkip: () -> Void = {}
    var onDone: () -> Void = {}
    private var windows: [NSWindow] = []
    private var showingBeast: Bool?

    func show(store: SessionStore) {
        let beast = store.engine.settings.beastModeEnabled
        if windows.isEmpty || showingBeast != beast {
            build(store: store)
        }
        for w in windows { w.orderFrontRegardless() }
    }

    func hide() {
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
        showingBeast = nil
    }

    private func build(store: SessionStore) {
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
        showingBeast = store.engine.settings.beastModeEnabled
        for screen in NSScreen.screens {
            let win = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            win.setFrame(screen.frame, display: true)
            win.isOpaque = true
            win.backgroundColor = .black
            win.level = .screenSaver
            win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            win.ignoresMouseEvents = false
            win.hasShadow = false
            win.isReleasedWhenClosed = false
            win.animationBehavior = .none
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
            host.view.frame = screen.frame
            win.contentViewController = host
            windows.append(win)
        }
    }
}
