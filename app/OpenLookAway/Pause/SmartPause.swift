import AppKit
import CoreAudio
import CoreMediaIO
import Foundation

struct PauseSignal: Equatable {
    var paused: Bool
    var reason: String?
}

final class SmartPause {
    private var tap: CFMachPort?
    private var lastMeetingCheck = Date.distantPast
    private var lastMeeting = false
    private var videoBundleIDs: Set<String> = [
        "com.apple.TV",
        "com.colliderli.iina",
        "org.videolan.vlc",
        "com.apple.QuickTimePlayerX"
    ]

    var hasEventTap: Bool { tap != nil }

    func retryTap() {}

    func poll(settings: AppSettings) -> PauseSignal {
        if settings.pauseDenylist, let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           settings.denylistBundleIDs.contains(id) {
            return PauseSignal(paused: true, reason: "Denylisted app")
        }
        if settings.pauseMeetings, micOrCameraInUse() {
            return PauseSignal(paused: true, reason: "Meeting")
        }
        if settings.pauseVideo, videoPlaying() {
            return PauseSignal(paused: true, reason: "Video playback")
        }
        if settings.pauseTyping, typingOrDragging() {
            return PauseSignal(paused: true, reason: "Typing")
        }
        if settings.pauseIdle {
            let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
            let keyIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
            if min(idle, keyIdle) >= settings.idleThresholdSeconds {
                return PauseSignal(paused: true, reason: "Idle")
            }
        }
        return PauseSignal(paused: false, reason: nil)
    }

    private func typingOrDragging() -> Bool {
        let key = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let left = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDragged)
        let right = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .rightMouseDragged)
        let other = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .otherMouseDragged)
        return min(key, left, right, other) < 1.5
    }

    private func micOrCameraInUse() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastMeetingCheck) < 5 {
            return lastMeeting
        }
        lastMeetingCheck = now
        lastMeeting = micInUse() || cameraInUse()
        return lastMeeting
    }

    private func micInUse() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultAddress, 0, nil, &size, &deviceID) == noErr,
              deviceID != kAudioObjectUnknown else { return false }
        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &running) == noErr else { return false }
        return running != 0
    }

    private func cameraInUse() -> Bool {
        var opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        var dataSize: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, &dataSize) == noErr,
              dataSize > 0 else { return false }
        let count = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        var devices = [CMIOObjectID](repeating: 0, count: count)
        var dataUsed: UInt32 = 0
        guard CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, dataSize, &dataUsed, &devices) == noErr else {
            return false
        }
        var runningAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        for device in devices {
            var running: UInt32 = 0
            var used: UInt32 = 0
            let size = UInt32(MemoryLayout<UInt32>.size)
            if CMIOObjectGetPropertyData(device, &runningAddress, 0, nil, size, &used, &running) == noErr, running != 0 {
                return true
            }
        }
        return false
    }

    private func videoPlaying() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              videoBundleIDs.contains(app) else { return false }
        return deviceRunning(selector: kAudioHardwarePropertyDefaultOutputDevice)
    }

    private func deviceRunning(selector: AudioObjectPropertySelector) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultAddress, 0, nil, &size, &deviceID) == noErr,
              deviceID != kAudioObjectUnknown else { return false }
        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &running) == noErr else { return false }
        return running != 0
    }
}
