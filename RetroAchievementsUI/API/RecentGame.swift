//
//  Profile.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation

struct RecentGame: Codable, Identifiable {
    let id: Int
    let consoleID: Int
    let consoleName: String
    let title: String
    let imageIcon: String
    let imageTitle: String
    let imageIngame: String
    let imageBoxArt: String
    let lastPlayed: String // This could be converted to Date if needed
    let achievementsTotal: Int
    let numPossibleAchievements: Int
    let possibleScore: Int
    let numAchieved: Int
    let scoreAchieved: Int
    let numAchievedHardcore: Int
    let scoreAchievedHardcore: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "GameID"
        case consoleID = "ConsoleID"
        case consoleName = "ConsoleName"
        case title = "Title"
        case imageIcon = "ImageIcon"
        case imageTitle = "ImageTitle"
        case imageIngame = "ImageIngame"
        case imageBoxArt = "ImageBoxArt"
        case lastPlayed = "LastPlayed"
        case achievementsTotal = "AchievementsTotal"
        case numPossibleAchievements = "NumPossibleAchievements"
        case possibleScore = "PossibleScore"
        case numAchieved = "NumAchieved"
        case scoreAchieved = "ScoreAchieved"
        case numAchievedHardcore = "NumAchievedHardcore"
        case scoreAchievedHardcore = "ScoreAchievedHardcore"
    }
}
