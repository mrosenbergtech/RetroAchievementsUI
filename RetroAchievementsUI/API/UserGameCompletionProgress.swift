//
//  UserGameCompletionProgress.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation

struct GameDetails: Codable, Identifiable {
    let id: Int
    let title: String
    let imageIcon: String
    let consoleID: Int
    let consoleName: String
    let maxPossible: Int
    let numAwarded: Int
    let numAwardedHardcore: Int
    let mostRecentAwardedDate: String
    let highestAwardKind: String?
    let highestAwardDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "GameID"
        case title = "Title"
        case imageIcon = "ImageIcon"
        case consoleID = "ConsoleID"
        case consoleName = "ConsoleName"
        case maxPossible = "MaxPossible"
        case numAwarded = "NumAwarded"
        case numAwardedHardcore = "NumAwardedHardcore"
        case mostRecentAwardedDate = "MostRecentAwardedDate"
        case highestAwardKind = "HighestAwardKind"
        case highestAwardDate = "HighestAwardDate"
    }
}

struct UserGameCompletionProgress: Codable {
    let count: Int
    let total: Int
    let results: [GameDetails]
    
    enum CodingKeys: String, CodingKey {
        case count = "Count"
        case total = "Total"
        case results = "Results"
    }
}
