import XCTest
@testable import OpenLookAway

final class AppVersionTests: XCTestCase {
    func testParsesGitTags() {
        XCTAssertEqual(AppVersion("1.2.3")?.components, [1, 2, 3])
        XCTAssertEqual(AppVersion("v1.2.3")?.components, [1, 2, 3])
        XCTAssertEqual(AppVersion("  v2.0 ")?.components, [2, 0])
        XCTAssertEqual(AppVersion("1.2.3-beta.1")?.components, [1, 2, 3])
    }

    func testRefusesNonVersions() {
        XCTAssertNil(AppVersion("nightly"))
        XCTAssertNil(AppVersion(""))
        XCTAssertNil(AppVersion("v"))
    }

    func testOrdersByNumberNotText() {
        XCTAssertLessThan(AppVersion("1.9.0")!, AppVersion("1.10.0")!)
        XCTAssertLessThan(AppVersion("1.2.0")!, AppVersion("1.2.1")!)
        XCTAssertGreaterThan(AppVersion("2.0.0")!, AppVersion("1.99.99")!)
    }

    func testMissingTrailingComponentsAreZero() {
        XCTAssertEqual(AppVersion("1.2")!, AppVersion("1.2.0")!)
        XCTAssertFalse(AppVersion("1.2")! < AppVersion("1.2.0")!)
        XCTAssertFalse(AppVersion("1.2.0")! < AppVersion("1.2")!)
    }
}

final class UpdateCheckTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private static let now = Date(timeIntervalSince1970: 1_770_000_000)

    override func setUp() {
        super.setUp()
        suite = "ola.update.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    private func transport(tag: String, status: Int = 200) -> UpdateCheck.Transport {
        { request in
            let body = """
                {"tag_name": "\(tag)", "html_url": "https://github.com/x/y/releases/tag/\(tag)"}
                """
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil
            )!
            return (Data(body.utf8), response)
        }
    }

    func testReportsNewerRelease() async {
        let outcome = await UpdateCheck.latest(currentVersion: "1.0.0", transport: transport(tag: "v1.1.0"))
        XCTAssertEqual(outcome.available?.version, "1.1.0")
        XCTAssertEqual(outcome.available?.url.absoluteString, "https://github.com/x/y/releases/tag/v1.1.0")
    }

    func testQuietWhenCurrentOrAhead() async {
        let same = await UpdateCheck.latest(currentVersion: "1.1.0", transport: transport(tag: "v1.1.0"))
        XCTAssertEqual(same, .upToDate)
        let ahead = await UpdateCheck.latest(currentVersion: "1.2.0", transport: transport(tag: "v1.1.0"))
        XCTAssertEqual(ahead, .upToDate)
    }

    func testFailuresHaveNoAvailableUpdate() async {
        let limited = await UpdateCheck.latest(currentVersion: "1.0.0", transport: transport(tag: "v9.0.0", status: 403))
        XCTAssertNil(limited.available)
        let offline = await UpdateCheck.latest(currentVersion: "1.0.0", transport: { _ in
            throw URLError(.notConnectedToInternet)
        })
        XCTAssertNil(offline.available)
    }

    func testSendsGitHubHeaders() async {
        nonisolated(unsafe) var captured: URLRequest?
        _ = await UpdateCheck.latest(currentVersion: "1.0.0", transport: { request in
            captured = request
            return try await self.transport(tag: "v1.1.0")(request)
        })
        XCTAssertEqual(captured?.url, UpdateCheck.latestReleaseURL)
        XCTAssertEqual(captured?.value(forHTTPHeaderField: "User-Agent")?.isEmpty, false)
        XCTAssertEqual(captured?.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
    }

    func testOffMeansNoRequest() async {
        UpdateCheck.setEnabled(false, defaults: defaults)
        nonisolated(unsafe) var asked = false
        let outcome = await UpdateCheck.run(
            .periodic, defaults: defaults, currentVersion: "1.0.0", now: Self.now,
            transport: { request in
                asked = true
                return try await self.transport(tag: "v2.0.0")(request)
            }
        )
        XCTAssertEqual(outcome, .skipped)
        XCTAssertFalse(asked)
    }

    func testChecksAtMostOncePerDay() async {
        let first = await UpdateCheck.run(
            .periodic, defaults: defaults, currentVersion: "1.0.0", now: Self.now,
            transport: transport(tag: "v2.0.0")
        )
        XCTAssertNotNil(first.available)
        nonisolated(unsafe) var asked = false
        let soon = await UpdateCheck.run(
            .periodic, defaults: defaults, currentVersion: "1.0.0",
            now: Self.now.addingTimeInterval(3600),
            transport: { request in
                asked = true
                return try await self.transport(tag: "v2.0.0")(request)
            }
        )
        XCTAssertEqual(soon, .skipped)
        XCTAssertFalse(asked)
        let tomorrow = await UpdateCheck.run(
            .periodic, defaults: defaults, currentVersion: "1.0.0",
            now: Self.now.addingTimeInterval(UpdateCheck.interval + 1),
            transport: transport(tag: "v2.0.0")
        )
        XCTAssertNotNil(tomorrow.available)
    }

    func testLaunchIgnoresInterval() async {
        _ = await UpdateCheck.run(
            .launch, defaults: defaults, currentVersion: "1.0.0", now: Self.now,
            transport: transport(tag: "v2.0.0")
        )
        let again = await UpdateCheck.run(
            .launch, defaults: defaults, currentVersion: "1.0.0",
            now: Self.now.addingTimeInterval(60),
            transport: transport(tag: "v2.0.0")
        )
        XCTAssertEqual(again.available?.version, "2.0.0")
    }

    func testManualRunsWhenAutomaticOff() async {
        UpdateCheck.setEnabled(false, defaults: defaults)
        let outcome = await UpdateCheck.run(
            .manual, defaults: defaults, currentVersion: "1.0.0", now: Self.now,
            transport: transport(tag: "v2.0.0")
        )
        XCTAssertEqual(outcome.available?.version, "2.0.0")
    }

    func testDefaultsToOn() {
        XCTAssertTrue(UpdateCheck.isEnabled(defaults))
        XCTAssertTrue(UpdateCheck.isDue(.periodic, defaults: defaults, now: Self.now))
    }
}
