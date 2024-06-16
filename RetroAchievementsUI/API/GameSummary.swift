//
//  GameSummary.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation

struct GameSummary: Codable {
    let id: Int
    let title: String
    let consoleID: Int
    let forumTopicID: Int?
    let flags: Int? // Note: Use Optional<Int> instead of Int if flags can be null
    let imageIcon: String
    let imageTitle: String
    let imageIngame: String
    let imageBoxArt: String
    let publisher: String
    let developer: String
    let genre: String
    let released: String
    let isFinal: Int
    let richPresencePatch: String
    let playersTotal: Int
    let achievementsPublished: Int
    let pointsTotal: Int
    let guideURL: String? // Note: Use Optional<String> instead of String if guideURL can be null
    let consoleName: String
    let parentGameID: Int? // Note: Use Optional<Int> instead of Int if parentGameID can be null
    let numDistinctPlayers: Int
    let numAchievements: Int
    let achievements: [String: Achievement]
    let numAwardedToUser: Int
    let numAwardedToUserHardcore: Int
    let numDistinctPlayersCasual: Int
    let numDistinctPlayersHardcore: Int
    let userCompletion: String
    let userCompletionHardcore: String
    let highestAwardKind: String?
    let highestAwardDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Title"
        case consoleID = "ConsoleID"
        case forumTopicID = "ForumTopicID"
        case flags = "Flags"
        case imageIcon = "ImageIcon"
        case imageTitle = "ImageTitle"
        case imageIngame = "ImageIngame"
        case imageBoxArt = "ImageBoxArt"
        case publisher = "Publisher"
        case developer = "Developer"
        case genre = "Genre"
        case released = "Released"
        case isFinal = "IsFinal"
        case richPresencePatch = "RichPresencePatch"
        case playersTotal = "players_total"
        case achievementsPublished = "achievements_published"
        case pointsTotal = "points_total"
        case guideURL = "GuideURL"
        case consoleName = "ConsoleName"
        case parentGameID = "ParentGameID"
        case numDistinctPlayers = "NumDistinctPlayers"
        case numAchievements = "NumAchievements"
        case achievements = "Achievements"
        case numAwardedToUser = "NumAwardedToUser"
        case numAwardedToUserHardcore = "NumAwardedToUserHardcore"
        case numDistinctPlayersCasual = "NumDistinctPlayersCasual"
        case numDistinctPlayersHardcore = "NumDistinctPlayersHardcore"
        case userCompletion = "UserCompletion"
        case userCompletionHardcore = "UserCompletionHardcore"
        case highestAwardKind = "HighestAwardKind"
        case highestAwardDate = "HighestAwardDate"
    }
}
