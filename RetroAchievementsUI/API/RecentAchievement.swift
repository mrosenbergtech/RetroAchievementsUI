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
