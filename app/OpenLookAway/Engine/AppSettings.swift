import Foundation

enum SkipStyle: String, Codable, CaseIterable, Identifiable {
    case casual, balanced, hardcore
    var id: String { rawValue }
    var title: String {
        switch self {
        case .casual: return "Casual"
        case .balanced: return "Balanced"
        case .hardcore: return "Hardcore"
        }
    }
    var subtitle: String {
        switch self {
        case .casual: return "Skip anytime"
        case .balanced: return "Skip after a pause"
        case .hardcore: return "No skips allowed"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var focusMinutes: Int = 20
    var shortBreakSeconds: Int = 20
    var longBreakMinutes: Int = 5
    var longBreakEvery: Int = 3
    var beastModeEnabled: Bool = false
    var beastPushUps: Int = 10
    var skipStyle: SkipStyle = .balanced
    var snoozesPerDay: Int = 5
    var officeHoursEnabled: Bool = false
    var officeStartHour: Int = 9
    var officeStartMinute: Int = 0
    var officeEndHour: Int = 18
    var officeEndMinute: Int = 0
    var officeWeekdaysOnly: Bool = true
    var denylistBundleIDs: [String] = []
    var pauseTyping: Bool = true
    var pauseIdle: Bool = true
    var pauseMeetings: Bool = true
    var pauseVideo: Bool = true
    var pauseDenylist: Bool = true
    var idleThresholdSeconds: Double = 60

    var focusDuration: TimeInterval { TimeInterval(focusMinutes * 60) }
    var shortDuration: TimeInterval { TimeInterval(shortBreakSeconds) }
    var longDuration: TimeInterval { TimeInterval(longBreakMinutes * 60) }

    static let storageKey = "ola.settings.v1"

    static func load(defaults: UserDefaults = .standard) -> AppSettings {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return decoded
    }

    func save(defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}

enum Phase: Equatable {
    case idle
    case focusing
    case paused
    case headsUp
    case cursorCountdown
    case breaking
}

enum BreakKind: Equatable {
    case short, long
}
