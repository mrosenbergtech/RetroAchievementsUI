//
//  RAImageURL.swift
//  RetroAchievementsUI
//
//  One place that builds retroachievements.org asset URLs.
//
//  Previously each view concatenated its own string, and they disagreed about
//  the trailing slash — AwardDetailView used "https://retroachievements.org"
//  while every other view used "https://retroachievements.org/". Both happened
//  to work only because the two API fields differ in leading slash.
//

import Foundation

enum RAImageURL {

    private static let host = "https://retroachievements.org"

    /// Joins a host and an API-supplied path regardless of whether the path
    /// carries a leading slash.
    private static func make(_ path: String) -> URL? {
        guard !path.isEmpty else { return nil }
        let normalized = path.hasPrefix("/") ? path : "/" + path
        return URL(string: host + normalized)
    }

    /// Square game icon — `ImageIcon` on most game models.
    static func gameIcon(_ path: String?) -> URL? {
        guard let path else { return nil }
        return make(path)
    }

    /// Title screen — `ImageTitle`.
    static func titleScreen(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return make(path)
    }

    static func avatar(_ userPic: String?) -> URL? {
        make(userPic ?? "/UserPic/retroachievementsUI")
    }

    /// Achievement badge. Unearned achievements use the `_lock` variant.
    static func badge(_ badgeName: String, locked: Bool) -> URL? {
        URL(string: "\(host)/Badge/\(badgeName)\(locked ? "_lock" : "").png")
    }
}
