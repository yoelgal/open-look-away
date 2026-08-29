import AppKit
import SwiftUI

@main
struct OpenLookAwayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Custom settings window observes the store; this scene must not.
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = SessionStore()
    private var item: NSStatusItem?
    private var panel: NSPanel?
    private var settingsWindow: NSWindow?
    private var onboarding: OnboardingWindowController?
    private var lastChip = ""
    private var lastBeast = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "ola.status"
        item.button?.imagePosition = .imageOnly
        item.button?.target = self
        item.button?.action = #selector(handleStatusClick)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        self.item = item
        store.onStatusChange = { [weak self] in self?.refreshTitle() }
        refreshTitle()
        store.openSettings = { [weak self] in self?.showSettings() }
        store.startUpdateChecks()
        if store.needsOnboarding {
            let controller = OnboardingWindowController()
            onboarding = controller
            controller.show(store: store) { [weak self] in
                self?.onboarding = nil
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func handleStatusClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            store.setManualPaused(!store.manualPaused)
            return
        }
        if NSEvent.modifierFlags.contains(.option) {
            store.jumpToHeadsUp()
        }
        if panel?.isVisible == true {
            hidePanel()
            return
        }
        showPanel()
    }
    private func showSettings() {
        hidePanel()
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 500),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.installGlassHost(SettingsView(store: store))
            window.center()
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.settingsWindow?.discardHostedContent()
                    self?.settingsWindow = nil
                    if self?.onboarding == nil {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
            }
            settingsWindow = window
        }
        NSApp.setActivationPolicy(.regular)
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
            panel.hasShadow = true
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.installGlassHost(QuickLookView(store: store), cornerRadius: 18)
            self.panel = panel
        }
        guard let panel, let button = item?.button, let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        panel.setFrameOrigin(NSPoint(x: buttonRect.maxX - 360, y: buttonRect.minY - 410))
        store.panelOpen = true
        panel.orderFrontRegardless()
    }

    private func hidePanel() {
        store.panelOpen = false
        panel?.discardHostedContent()
        panel = nil
    }

    private func refreshTitle() {
        item?.button?.title = ""
        item?.button?.imagePosition = .imageOnly
        let text = StatusChip.label(for: store.engine)
        let beast = store.engine.isBeast
        if text == lastChip, beast == lastBeast { return }
        lastChip = text
        lastBeast = beast
        let image = StatusChip.image(text: text, beast: beast)
        image.isTemplate = false
        item?.button?.image = image
    }
}
