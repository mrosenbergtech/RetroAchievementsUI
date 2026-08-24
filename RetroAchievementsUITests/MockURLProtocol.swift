//
//  MockURLProtocol.swift
//  RetroAchievementsUITests
//
//  Intercepts every request made through a session configured with it, so the
//  API layer can be exercised without touching the network.
//
//  No test in this bundle is permitted to reach retroachievements.org: an
//  unstubbed request fails the request rather than falling through.
//

import Foundation

final class MockURLProtocol: URLProtocol {

    /// What to return for a given request. Set per test.
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    /// Every URL the subject requested, in order. Lets tests assert on query
    /// parameters and on how *many* calls were made.
    nonisolated(unsafe) private(set) static var requestedURLs: [URL] = []
    private static let lock = NSLock()

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        handler = nil
        requestedURLs = []
    }

    static func record(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        requestedURLs.append(url)
    }

    static var recordedURLs: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return requestedURLs
    }

    /// Count of recorded requests whose path contains `fragment`.
    static func callCount(containing fragment: String) -> Int {
        recordedURLs.filter { $0.absoluteString.contains(fragment) }.count
    }

    // MARK: - A session configured to use this protocol

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let url = request.url { Self.record(url) }

        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: MockError.noHandler)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    enum MockError: Error {
        case noHandler
    }
}

// MARK: - Response helpers

extension MockURLProtocol {

    static func response(_ url: URL, status: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    /// Always returns `data` with a 200.
    static func respondAlways(with data: Data, status: Int = 200) {
        handler = { request in
            (response(request.url!, status: status), data)
        }
    }

    /// Routes by URL fragment — the usual case, since one profile fetch hits
    /// six different endpoints concurrently.
    ///
    /// A request matching no route returns 404 with empty data, so a test that
    /// forgets a route fails loudly instead of hanging.
    static func route(_ routes: [String: Data], status: Int = 200) {
        handler = { request in
            let url = request.url!
            for (fragment, data) in routes where url.absoluteString.contains(fragment) {
                return (response(url, status: status), data)
            }
            return (response(url, status: 404), Data())
        }
    }

    /// Fails the first `count` requests with `status`, then serves `data`.
    /// Used to drive the 429 retry path.
    static func failFirst(_ count: Int, status: Int, thenRespondWith data: Data) {
        let remaining = Counter(count)
        handler = { request in
            let url = request.url!
            if remaining.decrementIfPositive() {
                return (response(url, status: status), Data())
            }
            return (response(url, status: 200), data)
        }
    }

    /// Small thread-safe counter — the handler is called from URLSession's queue.
    final class Counter: @unchecked Sendable {
        private var value: Int
        private let lock = NSLock()

        init(_ value: Int) { self.value = value }

        func decrementIfPositive() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            guard value > 0 else { return false }
            value -= 1
            return true
        }
    }
}
