import AppKit
import SwiftUI

@MainActor
final class HeadsUpController {
    private weak var store: SessionStore?
    private var window: NSPanel?

    init(store: SessionStore) { self.store = store }

    func show() {
        guard let store else { return }
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 140),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.titleVisibility = .hidden
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.installGlassHost(HeadsUpToast(store: store), cornerRadius: 16)
            window = panel
        }
        guard let window, !window.isVisible else { return }
        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            window.setFrameOrigin(NSPoint(x: f.maxX - 380, y: f.maxY - 170))
        }
        window.orderFrontRegardless()
    }

    func hide() {
        window?.discardHostedContent()
        window = nil
    }
}

struct HeadsUpToast: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(time)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .monospacedDigit()
            Text("Almost time")
                .foregroundStyle(.secondary)
            HStack {
                Button("Start now") { store.startBreakNow() }
                Button("+1m") { store.snooze(minutes: 1) }
                Button("+5m") { store.snooze(minutes: 5) }
                Button("+15m") { store.snooze(minutes: 15) }
            }
        }
        .padding(16)
        .frame(width: 340, alignment: .leading)
        .background {
            OpaqueGlass().clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var time: String {
        let s = max(0, Int(store.engine.remainingFocus.rounded(.down)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
