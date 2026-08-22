import AppKit
import Foundation
import ServiceManagement

enum Onboarding {
    static let flagKey = "ola.onboarding.v1"

    static func needsOnboarding(defaults: UserDefaults) -> Bool {
        if defaults.bool(forKey: flagKey) { return false }
        if defaults.data(forKey: AppSettings.storageKey) != nil { return false }
        return true
    }

    static func markFinished(defaults: UserDefaults) {
        defaults.set(true, forKey: flagKey)
    }

    static func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func setOpenAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Login item is optional. Setup still finishes.
        }
    }

    static var opensAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }
}

enum TimingPreset: String, CaseIterable, Identifiable {
    case balanced
    case eyeCare
    case deepFocus
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced: return "20 / 20"
        case .eyeCare: return "15 / 15"
        case .deepFocus: return "45 / 30"
        case .custom: return "Custom"
        }
    }

    var subtitle: String {
        switch self {
        case .balanced: return "20 min focus, 20 s break"
        case .eyeCare: return "15 min focus, 15 s break"
        case .deepFocus: return "45 min focus, 30 s break"
        case .custom: return "Set your own times"
        }
    }

    var focusMinutes: Int? {
        switch self {
        case .balanced: return 20
        case .eyeCare: return 15
        case .deepFocus: return 45
        case .custom: return nil
        }
    }

    var shortBreakSeconds: Int? {
        switch self {
        case .balanced: return 20
        case .eyeCare: return 15
        case .deepFocus: return 30
        case .custom: return nil
        }
    }
}
