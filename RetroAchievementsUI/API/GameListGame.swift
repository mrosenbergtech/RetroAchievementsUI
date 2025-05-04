//
//  GameListGame.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 12/30/24.
//

import Foundation

struct GameListGame: Codable, Identifiable, Hashable {
    let title: String
    let id: Int
    let consoleID: Int
    let consoleName: String
    let imageIcon: String
    let numAchievements: Int
    let numLeaderboards: Int
    let points: Int
    let dateModified: String?
    let forumTopicID: Int?
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case id = "ID"
        case consoleID = "ConsoleID"
        case consoleName = "ConsoleName"
        case imageIcon = "ImageIcon"
        case numAchievements = "NumAchievements"
        case numLeaderboards = "NumLeaderboards"
        case points = "Points"
        case dateModified = "DateModified"
        case forumTopicID = "ForumTopicID"
    }
}
