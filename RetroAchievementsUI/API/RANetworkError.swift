//
//  RANetworkError.swift
//  RetroAchievementsUI
//
//  Why a request failed, in terms the UI can act on.
//
//  Every API call used to collapse into `Data?`, so a revoked key, an outage, a
//  rate limit and "no data yet" were indistinguishable — the app just showed
//  skeletons or an empty state forever with nothing to retry. This keeps enough
//  detail to say what happened and whether trying again is worth it.
//

import Foundation

enum RANetworkError: Error, Equatable {
    /// The device has no usable connection.
    case offline
    /// The request timed out.
    case timedOut
    /// 401/403 — the Web API key is wrong, revoked, or the username no longer matches.
    case unauthorized
    /// 429, still rate limited after the backoff retries.
    case rateLimited
    /// Any other non-2xx status.
    case server(Int)
    /// The response arrived but did not match the expected shape.
    case decoding
    /// Anything else, carrying the system's description.
    case transport(String)

    // MARK: - Presentation

    var title: String {
        switch self {
        case .offline:      return "You're Offline"
        case .timedOut:     return "Request Timed Out"
        case .unauthorized: return "Sign In Again"
        case .rateLimited:  return "Too Many Requests"
        case .server:       return "RetroAchievements Is Unavailable"
        case .decoding:     return "Unexpected Response"
        case .transport:    return "Something Went Wrong"
        }
    }

    var message: String {
        switch self {
        case .offline:
            return "Check your connection and try again."
        case .timedOut:
            return "The server took too long to respond."
        case .unauthorized:
            return "Your Web API key was rejected. Open Settings to sign in again."
        case .rateLimited:
            return "RetroAchievements is limiting requests. Wait a moment and try again."
        case .server(let code):
            return "The server responded with an error (\(code)). This is usually temporary."
        case .decoding:
            return "The server sent something this version of the app couldn't read."
        case .transport(let description):
            return description
        }
    }

    var systemImage: String {
        switch self {
        case .offline:      return "wifi.slash"
        case .timedOut:     return "clock.badge.exclamationmark"
        case .unauthorized: return "key.slash"
        case .rateLimited:  return "hourglass"
        case .server:       return "exclamationmark.icloud"
        case .decoding:     return "questionmark.square.dashed"
        case .transport:    return "exclamationmark.triangle"
        }
    }

    /// Whether the fix is in Settings rather than a retry.
    var requiresSignIn: Bool { self == .unauthorized }

    /// Bad credentials will not fix themselves; everything else might.
    var isWorthRetrying: Bool { !requiresSignIn }

    /// Whether this is worth interrupting the user for when the screen already
    /// has content on it.
    ///
    /// Rate limiting is a normal part of using this API, not a malfunction —
    /// the client already backs off and retries, and the next refresh will
    /// almost certainly succeed. Raising a banner every time a burst of
    /// requests gets throttled would train the user to ignore banners. So a
    /// throttle that leaves usable data on screen stays quiet; it is only
    /// reported when there is nothing to show and the user would otherwise be
    /// staring at a blank screen.
    var deservesBannerOverExistingData: Bool {
        self != .rateLimited
    }

    /// Ranking used when several concurrent requests fail at once, so the
    /// banner reports the most actionable cause rather than whichever landed
    /// last. A rejected key outranks a flaky connection.
    ///
    /// Throttling ranks *lowest* deliberately. It is expected, it heals itself,
    /// and it is suppressed over existing data — so if it outranked a real
    /// failure it would win the slot and then silently hide it.
    var severity: Int {
        switch self {
        case .unauthorized: return 5
        case .offline:      return 4
        case .server:       return 3
        case .timedOut:     return 3
        case .decoding:     return 2
        case .transport:    return 2
        case .rateLimited:  return 1
        }
    }

    /// Maps a URLSession failure onto a case the UI can explain.
    static func from(_ error: Error) -> RANetworkError {
        guard let urlError = error as? URLError else {
            return .transport(error.localizedDescription)
        }

        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost,
             .dataNotAllowed, .internationalRoamingOff:
            return .offline
        case .timedOut:
            return .timedOut
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .server(0)
        default:
            return .transport(urlError.localizedDescription)
        }
    }
}
