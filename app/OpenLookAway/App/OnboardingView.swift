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

    private let accent = Color(red: 0.20, green: 0.48, blue: 0.96)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("OpenLookAway")
                    .font(.system(size: 22, weight: .semibold))
                Text("Set your rhythm, then grant typing pause.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 22)

            Text("Timing")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            HStack(spacing: 8) {
                ForEach(TimingPreset.allCases) { item in
                    Button {
                        preset = item
                        if let focus = item.focusMinutes { focusMinutes = focus }
                        if let pause = item.shortBreakSeconds { shortBreakSeconds = pause }
                    } label: {
                        Text(item.title)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(preset == item ? accent : Color.primary.opacity(0.08))
                            )
                            .foregroundStyle(preset == item ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(preset.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Fixed slot so Custom never shifts the rest of the layout.
            VStack(alignment: .leading, spacing: 8) {
                if preset == .custom {
                    Stepper("Focus  \(focusMinutes) min", value: $focusMinutes, in: 1...120)
                    Stepper("Short break  \(shortBreakSeconds)s", value: $shortBreakSeconds, in: 5...120)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64, maxHeight: 64, alignment: .topLeading)
            .padding(.top, 8)

            Divider()
                .padding(.vertical, 16)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Typing pause")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: accessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(accessibilityTrusted ? Color(nsColor: .systemGreen) : Color(nsColor: .systemOrange))
                        Text(accessibilityTrusted ? "Granted" : "Not granted")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(accessibilityTrusted ? Color(nsColor: .systemGreen) : Color(nsColor: .systemOrange))
                    }
                }
                Text("macOS Accessibility lets OpenLookAway notice typing so a break can wait until you pause.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !accessibilityTrusted {
                    Button("Grant in System Settings") {
                        Onboarding.requestAccessibility()
                        accessibilityTrusted = Onboarding.isAccessibilityTrusted
                    }
                }
            }

            Toggle("Open at login", isOn: $openAtLogin)
                .toggleStyle(.checkbox)
                .padding(.top, 14)
                .onChange(of: openAtLogin) { on in
                    Onboarding.setOpenAtLogin(on)
                    openAtLogin = Onboarding.opensAtLogin
                }

            Text("Turn on Beast Mode later if you want a pump on every break.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 12)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Start now") {
                    Onboarding.setOpenAtLogin(openAtLogin)
                    store.finishOnboarding(
                        focusMinutes: focusMinutes,
                        shortBreakSeconds: shortBreakSeconds,
                        accessibilityGranted: Onboarding.isAccessibilityTrusted
                    )
                    onFinished()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(accent)
            }
            .padding(.bottom, 8)
        }
        .padding(28)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(width: 540, height: 470)
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
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 500),
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
        // Closing without Start now keeps setup pending. Timer stays off.
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
