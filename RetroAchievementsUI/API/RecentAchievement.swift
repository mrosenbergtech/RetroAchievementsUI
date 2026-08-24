//
//  RecentAchievement.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 12/28/24.
//

import Foundation

struct RecentAchievement: Codable, Identifiable {
        let id: Int
        let date: String
        let hardcoreMode: Int
        let title: String
        let description: String
        let badgeName: String
        let points: Int
        let trueRatio: Int
        let type: String?
        let author: String
        let gameTitle: String
        let gameIcon: String
        let gameID: Int
        let consoleName: String
        let badgeURL: String
        let gameURL: String
        
        // Define the coding keys to match the JSON keys
        enum CodingKeys: String, CodingKey {
            case id = "AchievementID"
            case date = "Date"
            case hardcoreMode = "HardcoreMode"
            case title = "Title"
            case description = "Description"
            case badgeName = "BadgeName"
            case points = "Points"
            case trueRatio = "TrueRatio"
            case type = "Type"
            case author = "Author"
            case gameTitle = "GameTitle"
            case gameIcon = "GameIcon"
            case gameID = "GameID"
            case consoleName = "ConsoleName"
            case badgeURL = "BadgeURL"
            case gameURL = "GameURL"
        }
    }

extension RecentAchievement {

    /// GetUserRecentAchievements returns "yyyy-MM-dd HH:mm:ss" in UTC.
    ///
    /// The formatters are static: the row that used to own this rebuilt two
    /// DateFormatters on every render, and used "YYYY" — the ISO week-year,
    /// which reports the following year for dates in late December.
    private static let apiFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(abbreviation: "UTC")
        return f
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    static func relativeDate(_ raw: String) -> String? {
        guard let date = apiFormatter.date(from: raw) else { return nil }
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
