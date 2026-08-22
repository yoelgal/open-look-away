import AppKit
import SwiftUI

@MainActor
final class CursorCountdownController {
    private weak var store: SessionStore?
    private var window: NSPanel?
    private var follow: Timer?

    init(store: SessionStore) { self.store = store }

    func show() {
        guard let store else { return }
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 72, height: 72),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.ignoresMouseEvents = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: CursorCountdownView(store: store))
            window = panel
        }
        window?.orderFrontRegardless()
        if follow == nil {
            follow = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.reposition() }
            }
        }
        reposition()
    }

    func hide() {
        follow?.invalidate()
        follow = nil
        window?.orderOut(nil)
    }

    private func reposition() {
        guard let window else { return }
        let p = NSEvent.mouseLocation
        window.setFrameOrigin(NSPoint(x: p.x + 18, y: p.y - 80))
    }
}

struct CursorCountdownView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        Text("\(seconds)")
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .frame(width: 64, height: 64)
            .background(.ultraThinMaterial, in: Circle())
    }

    private var seconds: Int {
        max(0, Int(store.engine.remainingFocus.rounded(.up)))
    }
}
