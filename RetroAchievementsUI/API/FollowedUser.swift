//
//  FollowedUser.swift
//  RetroAchievementsUI
//
//  One entry from API_GetUsersIFollow.php — the site's follow list, which is
//  this app's "friends".
//
//  Read-only by necessity: the web API exposes who you follow but offers no
//  way to follow or unfollow, so adding someone happens on the website. Pinned
//  users (PinnedUsers) exist to cover that gap locally.
//
//  https://api-docs.retroachievements.org/v1/get-users-i-follow.html
//

import Foundation

struct FollowedUser: Codable, Identifiable, Hashable {
    let user: String
    let ulid: String?
    let points: Int
    let pointsSoftcore: Int
    /// Whether they follow back. Nil from endpoints that don't report it.
    let isFollowingMe: Bool?

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case ulid = "ULID"
        case points = "Points"
        case pointsSoftcore = "PointsSoftcore"
        case isFollowingMe = "IsFollowingMe"
    }

    /// Usernames are unique on RetroAchievements and are what every other
    /// endpoint keys on, so they identify a row better than the ULID, which
    /// this endpoint has been known to omit.
    var id: String { user }

    func points(hardcoreMode: Bool) -> Int {
        hardcoreMode ? points : pointsSoftcore
    }
}

struct FollowedUsersResult: Codable {
    let count: Int
    let total: Int
    let results: [FollowedUser]

    enum CodingKeys: String, CodingKey {
        case count = "Count"
        case total = "Total"
        case results = "Results"
    }
}
