//
//  Comment.swift
//  RetroAchievementsUI
//
//  A comment from API_GetComments.php.
//
//  https://api-docs.retroachievements.org/v1/get-comments.html
//

import Foundation

struct Comment: Codable {
    let user: String
    /// The *author's* ULID — repeated across every comment by that user, so it
    /// is not a per-comment identity. See `id`.
    let userULID: String?
    let submitted: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case userULID = "ULID"
        case submitted = "Submitted"
        case text = "CommentText"
    }
}

extension Comment: Identifiable {
    /// Composite identity. The API exposes no per-comment id, and `ULID`
    /// belongs to the author, so a user who comments twice would collide.
    var id: String { "\(user)-\(submitted)-\(text.hashValue)" }
}

extension Comment {
    /// RetroAchievements posts automated changelog entries ("X edited this
    /// achievement.") under the reserved "Server" account. They dominate the
    /// feed on older achievements and say nothing to a player.
    var isAutomated: Bool { user == "Server" }

    var submittedDate: Date? { Self.iso8601.date(from: submitted) }

    var relativeSubmitted: String? {
        guard let date = submittedDate else { return nil }
        return Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// "2019-02-15T21:02:16.000000Z" — ISO8601 with fractional seconds.
    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()
}

extension Array where Element == Comment {
    /// What a player actually wrote, newest first.
    ///
    /// The API returns oldest-first and mixes in automated "Server" changelog
    /// entries; on an old achievement those can be most of the thread, and the
    /// interesting remarks are the recent ones.
    var playerComments: [Comment] {
        filter { !$0.isAutomated }
            .sorted { ($0.submittedDate ?? .distantPast) > ($1.submittedDate ?? .distantPast) }
    }
}

struct CommentsResult: Codable {
    let count: Int
    let total: Int
    let results: [Comment]

    enum CodingKeys: String, CodingKey {
        case count = "Count"
        case total = "Total"
        case results = "Results"
    }
}

/// The `t` parameter of API_GetComments.php.
enum CommentTarget: Int {
    case game = 1
    case achievement = 2
    case user = 3
}
