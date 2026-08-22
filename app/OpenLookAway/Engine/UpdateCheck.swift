import Foundation

struct AppVersion: Comparable, Sendable, CustomStringConvertible {
    let components: [Int]
    let description: String

    init?(_ raw: String) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.first == "v" || text.first == "V" { text.removeFirst() }
        let core = text.prefix { $0.isNumber || $0 == "." }
        let parts = core.split(separator: ".").map { Int($0) }
        guard !parts.isEmpty, !parts.contains(where: { $0 == nil }) else { return nil }
        components = parts.compactMap { $0 }
        description = String(core)
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compare(lhs, rhs) < 0
    }

    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compare(lhs, rhs) == 0
    }

    private static func compare(_ lhs: AppVersion, _ rhs: AppVersion) -> Int {
        for index in 0..<max(lhs.components.count, rhs.components.count) {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right ? -1 : 1 }
        }
        return 0
    }
}

struct AvailableUpdate: Sendable, Equatable {
    let version: String
    let url: URL
}

enum UpdateCheck {
    static let repository = "yoelgal/open-look-away"
    static let enabledKey = "ola.updateCheckEnabled"
    static let lastCheckedKey = "ola.updateLastCheckedAt"
    static let interval: TimeInterval = 24 * 60 * 60

    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    static var latestReleaseURL: URL {
        URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
    }

    enum Trigger: Sendable {
        case launch, periodic, manual
        var honoursInterval: Bool { self == .periodic }
        var requiresSetting: Bool { self != .manual }
    }

    enum Outcome: Sendable, Equatable {
        case update(AvailableUpdate)
        case upToDate
        case failed(String)
        case skipped

        var available: AvailableUpdate? {
            if case .update(let update) = self { return update }
            return nil
        }
    }

    static func isEnabled(_ defaults: UserDefaults) -> Bool {
        if defaults.object(forKey: enabledKey) == nil { return true }
        return defaults.bool(forKey: enabledKey)
    }

    static func setEnabled(_ on: Bool, defaults: UserDefaults) {
        defaults.set(on, forKey: enabledKey)
    }

    static func isDue(_ trigger: Trigger, defaults: UserDefaults, now: Date = Date()) -> Bool {
        if trigger.requiresSetting, !isEnabled(defaults) { return false }
        guard trigger.honoursInterval else { return true }
        let seconds = defaults.double(forKey: lastCheckedKey)
        guard seconds > 0 else { return true }
        let last = Date(timeIntervalSince1970: seconds)
        return last > now || now.timeIntervalSince(last) >= interval
    }

    @discardableResult
    static func run(
        _ trigger: Trigger,
        defaults: UserDefaults,
        currentVersion: String,
        now: Date = Date(),
        transport: Transport? = nil
    ) async -> Outcome {
        guard isDue(trigger, defaults: defaults, now: now) else { return .skipped }
        defaults.set(now.timeIntervalSince1970, forKey: lastCheckedKey)
        return await latest(currentVersion: currentVersion, transport: transport)
    }

    static func latest(currentVersion: String, transport: Transport? = nil) async -> Outcome {
        guard let current = AppVersion(currentVersion) else {
            return .failed("This build has no version number to compare.")
        }
        var request = URLRequest(url: latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("OpenLookAway/\(current)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let data: Data
        let response: URLResponse
        do {
            if let transport {
                (data, response) = try await transport(request)
            } else {
                (data, response) = try await URLSession.shared.data(for: request)
            }
        } catch {
            return .failed("Could not reach GitHub. \(error.localizedDescription)")
        }

        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else {
            if code == 403 || code == 429 {
                return .failed("GitHub is rate-limiting this network. Try again later.")
            }
            return .failed("GitHub answered \(code).")
        }

        guard let release = try? JSONDecoder().decode(Release.self, from: data),
              let latest = AppVersion(release.tagName),
              let url = URL(string: release.htmlURL)
        else { return .failed("Could not read GitHub's answer.") }

        guard latest > current else { return .upToDate }
        return .update(AvailableUpdate(version: latest.description, url: url))
    }

    private struct Release: Decodable {
        let tagName: String
        let htmlURL: String
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }
}
