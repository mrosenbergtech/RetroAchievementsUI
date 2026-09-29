//
//  AchievementOfTheWeek.swift
//  RetroAchievementsUI
//
//  This week's featured achievement, from API_GetAchievementOfTheWeek.php.
//
//  The payload is its own shape rather than a plain Achievement: the game and
//  console arrive as nested objects, there is no badge name, and the unlock
//  counts are site-wide rather than per-user.
//
//  https://api-docs.retroachievements.org/v1/get-achievement-of-the-week.html
//

import Foundation

struct AchievementOfTheWeek: Codable {
    let achievement: Details
    let console: Named
    let game: Named
    let startAt: String?
    let totalPlayers: Int?
    let unlocksCount: Int?
    let unlocksHardcoreCount: Int?
    /// Everyone who has unlocked it, newest first. Capped by the API.
    let unlocks: [Unlock]?

    enum CodingKeys: String, CodingKey {
        case achievement = "Achievement"
        case console = "Console"
        case game = "Game"
        case startAt = "StartAt"
        case totalPlayers = "TotalPlayers"
        case unlocksCount = "UnlocksCount"
        case unlocksHardcoreCount = "UnlocksHardcoreCount"
        case unlocks = "Unlocks"
    }

    struct Details: Codable {
        let id: Int
        let title: String
        let description: String?
        let points: Int
        let trueRatio: Int?
        let type: String?
        let author: String?

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case title = "Title"
            case description = "Description"
            case points = "Points"
            case trueRatio = "TrueRatio"
            case type = "Type"
            case author = "Author"
        }
    }

    struct Named: Codable {
        let id: Int
        let title: String

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case title = "Title"
        }
    }

    struct Unlock: Codable {
        let user: String
        let dateAwarded: String?
        let hardcoreMode: Int?

        enum CodingKeys: String, CodingKey {
            case user = "User"
            case dateAwarded = "DateAwarded"
            case hardcoreMode = "HardcoreMode"
        }
    }
}

extension AchievementOfTheWeek {
    /// Whether `username` appears in the unlock list.
    ///
    /// The API caps `Unlocks`, so a false here means "not among the unlocks the
    /// API returned" rather than a guarantee. Used only to decorate the card,
    /// never to tell someone they haven't earned something.
    func isUnlocked(by username: String, hardcoreMode: Bool) -> Bool {
        guard let unlocks else { return false }
        return unlocks.contains {
            $0.user.caseInsensitiveCompare(username) == .orderedSame
            && (!hardcoreMode || $0.hardcoreMode == 1)
        }
    }

    /// "2023-10-23T00:00:00.000000Z" — same fractional-seconds ISO8601 the
    /// comment endpoint uses.
    var startDate: Date? {
        guard let startAt else { return nil }
        return Self.iso8601.date(from: startAt)
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
