//
//  SetClaim.swift
//  RetroAchievementsUI
//
//  An achievement-set development claim, from API_GetClaims.php (finished) and
//  API_GetActiveClaims.php (in progress).
//
//  This is the closest the API gets to a "new sets and revisions" feed. There
//  is no endpoint for "a set was published"; a completed claim is the event
//  that stands in for it, which is why the feed says "Completed" rather than
//  "Released". Claims can also be dropped or expire, so only completed ones
//  are shown as finished work.
//
//  https://api-docs.retroachievements.org/v1/get-claims.html
//  https://api-docs.retroachievements.org/v1/get-active-claims.html
//

import Foundation

struct SetClaim: Codable, Identifiable, Hashable {
    let id: Int
    let user: String
    let gameID: Int
    let gameTitle: String
    let gameIcon: String?
    let consoleID: Int?
    let consoleName: String
    let claimType: Int?
    let setType: Int
    let status: Int?
    let created: String?
    let doneTime: String?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case user = "User"
        case gameID = "GameID"
        case gameTitle = "GameTitle"
        case gameIcon = "GameIcon"
        case consoleID = "ConsoleID"
        case consoleName = "ConsoleName"
        case claimType = "ClaimType"
        case setType = "SetType"
        case status = "Status"
        case created = "Created"
        case doneTime = "DoneTime"
    }
}

extension SetClaim {
    /// Values taken from RetroAchievements' own client library
    /// (`ClaimSetType`), not guessed from samples.
    enum Kind: Int {
        case newSet = 0
        case revision = 1

        var label: String {
            switch self {
            case .newSet: return "NEW SET"
            case .revision: return "REVISION"
            }
        }
    }

    /// `ClaimStatus` in the same library.
    enum Status: Int {
        case active = 0
        case complete = 1
        case dropped = 2
    }

    /// Unknown values read as a new set rather than dropping the row: a claim
    /// the app cannot categorise is still news worth showing.
    var kind: Kind { Kind(rawValue: setType) ?? .newSet }

    var isRevision: Bool { kind == .revision }

    var claimStatus: Status? { status.flatMap(Status.init(rawValue:)) }

    /// A collaboration rather than the primary claim.
    var isCollaboration: Bool { claimType == 1 }

    /// When this claim became news.
    ///
    /// `DoneTime` means different things by status — completion for a finished
    /// claim, expiry for an active one — so an in-progress claim is dated by
    /// when it was *made*, which is the moment worth reporting.
    var newsDate: Date? {
        let raw = claimStatus == .complete ? doneTime : created
        return raw.flatMap(Self.apiFormatter.date(from:))
    }

    var relativeNewsDate: String? {
        guard let newsDate else { return nil }
        return Self.relativeFormatter.localizedString(for: newsDate, relativeTo: Date())
    }

    /// "2024-01-27 23:27:16" — the claims endpoints use the space-separated
    /// format, not the ISO8601 the comment endpoint returns.
    private static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

extension Array where Element == SetClaim {
    /// Newest first, one row per game, capped.
    ///
    /// Deduplicated by game because a set with two developers arrives as two
    /// claims — primary and collaboration — and a feed that lists the same
    /// game twice looks broken. The primary claim wins; failing that, the
    /// newer one.
    func asFeed(limit: Int = 100) -> [SetClaim] {
        var bestByGame: [Int: SetClaim] = [:]

        for claim in self {
            guard let existing = bestByGame[claim.gameID] else {
                bestByGame[claim.gameID] = claim
                continue
            }
            if existing.isCollaboration && !claim.isCollaboration {
                bestByGame[claim.gameID] = claim
            } else if existing.isCollaboration == claim.isCollaboration,
                      let new = claim.newsDate, let old = existing.newsDate, new > old {
                bestByGame[claim.gameID] = claim
            }
        }

        return bestByGame.values
            .sorted { ($0.newsDate ?? .distantPast) > ($1.newsDate ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }
}
