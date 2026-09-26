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

extension Comment {
    /// The comment text with any URLs in it marked up as tappable links.
    ///
    /// RetroAchievements comments are plain text — the site offers no markup —
    /// so a player sharing a video guide just pastes the URL, and the thread is
    /// full of bare "https://youtu.be/…" runs. NSDataDetector finds those, and
    /// knows to leave trailing punctuation out of the match, so "…see
    /// https://youtu.be/x." links the URL and not the full stop.
    ///
    /// The string is assembled span by span rather than by mapping String
    /// ranges onto an AttributedString's indices: the two index spaces are only
    /// convertible while the characters match exactly, and that is an easy
    /// guarantee to lose later.
    var linkedText: AttributedString {
        var result = AttributedString()
        var cursor = text.startIndex

        for match in Self.linkMatches(in: text) {
            guard let url = match.url,
                  let range = Range(match.range, in: text),
                  range.lowerBound >= cursor else { continue }

            result.append(AttributedString(String(text[cursor..<range.lowerBound])))

            var link = AttributedString(String(text[range]))
            link.link = url
            result.append(link)

            cursor = range.upperBound
        }

        result.append(AttributedString(String(text[cursor...])))
        return result
    }

    /// Every URL the comment mentions, in the order they appear.
    ///
    /// Drives the "Copy Link" actions, and lets a test assert on what was
    /// detected without picking an AttributedString apart.
    var links: [URL] {
        Self.linkMatches(in: text).compactMap(\.url)
    }

    private static func linkMatches(in text: String) -> [NSTextCheckingResult] {
        guard let detector = linkDetector, !text.isEmpty else { return [] }
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
    }

    /// `.link` also resolves bare "www.youtube.com/…" — which players write at
    /// least as often as the full URL — supplying an http:// scheme. That
    /// scheme is left alone rather than upgraded: guessing https on the
    /// author's behalf breaks http-only fan sites, and the destination
    /// redirects if it supports it.
    private static let linkDetector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()
}
