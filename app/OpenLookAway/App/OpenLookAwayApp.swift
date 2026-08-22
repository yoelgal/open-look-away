import AppKit
import Combine
import SwiftUI

@main
struct OpenLookAwayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(store: appDelegate.store)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = SessionStore()
    private var item: NSStatusItem?
    private var panel: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "ola.status"
        item.button?.image = NSImage(systemSymbolName: "circle", accessibilityDescription: "Open Look Away")
        item.button?.imagePosition = .imageLeading
        item.button?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        item.button?.sendAction(on: [.leftMouseUp])
        self.item = item
        store.objectWillChange.sink { [weak self] _ in
            self?.refreshTitle()
        }.store(in: &cancellables)
        refreshTitle()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func togglePanel() {
        if NSEvent.modifierFlags.contains(.option) {
            store.jumpToHeadsUp()
        }
        if panel?.isVisible == true {
            panel?.orderOut(nil)
            return
        }
        showPanel()
    }

    private func showPanel() {
        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 400),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: QuickLookView(store: store))
            self.panel = panel
        }
        guard let panel, let button = item?.button, let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        panel.setFrameOrigin(NSPoint(x: buttonRect.maxX - 360, y: buttonRect.minY - 410))
        panel.orderFrontRegardless()
    }

    private func refreshTitle() {
        let phase = store.engine.phase
        let t = phase == .breaking ? store.engine.remainingBreak : store.engine.remainingFocus
        let s = max(0, Int(t.rounded(.down)))
        let text: String
        switch phase {
        case .breaking: text = String(format: " %d:%02d", s / 60, s % 60)
        case .idle: text = " Off"
        case .paused: text = " Paused"
        default: text = String(format: " %d:%02d", s / 60, s % 60)
        }
        item?.button?.title = text
        item?.button?.image = NSImage(
            systemSymbolName: iconName,
            accessibilityDescription: "Open Look Away"
        )
    }

    private var iconName: String {
        switch store.engine.phase {
        case .breaking: return "eye"
        case .paused, .idle: return "pause.circle"
        case .headsUp, .cursorCountdown: return "eye.slash"
        case .focusing: return "circle"
        }
    }
}
