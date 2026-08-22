import AppKit
import SwiftUI

struct OnboardingView: View {
    var store: SessionStore
    var onFinished: () -> Void

    @State private var preset: TimingPreset = .balanced
    @State private var focusMinutes: Int = 20
    @State private var shortBreakSeconds: Int = 20
    @State private var openAtLogin = Onboarding.opensAtLogin
    @State private var accessibilityTrusted = Onboarding.isAccessibilityTrusted

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("OpenLookAway")
                .font(.system(size: 18, weight: .medium))
            Text("Set your rhythm, then grant typing pause.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Picker("Timing", selection: $preset) {
                ForEach(TimingPreset.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: preset) { next in
                if let focus = next.focusMinutes { focusMinutes = focus }
                if let pause = next.shortBreakSeconds { shortBreakSeconds = pause }
            }

            Text(preset.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if preset == .custom {
                Stepper("Focus \(focusMinutes) min", value: $focusMinutes, in: 1...120)
                Stepper("Short break \(shortBreakSeconds)s", value: $shortBreakSeconds, in: 5...120)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessibility")
                    Text(accessibilityTrusted ? "Granted. Typing pause can run." : "Needed so breaks wait while you type.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(accessibilityTrusted ? "Granted" : "Open Settings") {
                    Onboarding.requestAccessibility()
                    accessibilityTrusted = Onboarding.isAccessibilityTrusted
                }
                .disabled(accessibilityTrusted)
            }

            Toggle("Open at login", isOn: $openAtLogin)
                .onChange(of: openAtLogin) { on in
                    Onboarding.setOpenAtLogin(on)
                    openAtLogin = Onboarding.opensAtLogin
                }

            HStack {
                Spacer()
                Button("Start") {
                    Onboarding.setOpenAtLogin(openAtLogin)
                    store.finishOnboarding(
                        focusMinutes: focusMinutes,
                        shortBreakSeconds: shortBreakSeconds,
                        accessibilityGranted: Onboarding.isAccessibilityTrusted
                    )
                    onFinished()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .padding(.top, 16)
        .frame(width: 520, height: 400)
        .background(Color.clear)
        .onAppear {
            accessibilityTrusted = Onboarding.isAccessibilityTrusted
            openAtLogin = Onboarding.opensAtLogin
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            accessibilityTrusted = Onboarding.isAccessibilityTrusted
        }
    }
}

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var store: SessionStore?
    private var onFinished: (() -> Void)?

    func show(store: SessionStore, onFinished: @escaping () -> Void) {
        self.store = store
        self.onFinished = onFinished
        NSApp.setActivationPolicy(.regular)
        if window == nil {
            let root = OnboardingView(store: store) { [weak self] in
                self?.finishFromButton()
            }
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "OpenLookAway"
            window.titleVisibility = .hidden
            window.isReleasedWhenClosed = false
            window.installGlassHost(root)
            window.delegate = self
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard let store, store.needsOnboarding else {
            NSApp.setActivationPolicy(.accessory)
            return
        }
        store.finishOnboarding(
            focusMinutes: 20,
            shortBreakSeconds: 20,
            accessibilityGranted: Onboarding.isAccessibilityTrusted
        )
        NSApp.setActivationPolicy(.accessory)
        onFinished?()
        onFinished = nil
    }

    private func finishFromButton() {
        window?.delegate = nil
        window?.orderOut(nil)
        window = nil
        NSApp.setActivationPolicy(.accessory)
        onFinished?()
        onFinished = nil
    }
}
