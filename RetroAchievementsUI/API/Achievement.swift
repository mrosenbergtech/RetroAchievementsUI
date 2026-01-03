//
//  Achievement.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/13/24.
//

import Foundation

struct Achievement: Codable {
    let id: Int
    let numAwarded: Int
    let numAwardedHardcore: Int
    let title: String
    let description: String
    let points: Int
    let trueRatio: Int
    let author: String
    let dateModified: String?
    let dateCreated: String
    let badgeName: String
    let displayOrder: Int
    let memAddr: String
    let type: String?
    let dateEarnedHardcore: String?
    let dateEarned: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case numAwarded = "NumAwarded"
        case numAwardedHardcore = "NumAwardedHardcore"
        case title = "Title"
        case description = "Description"
        case points = "Points"
        case trueRatio = "TrueRatio"
        case author = "Author"
        case dateModified = "DateModified"
        case dateCreated = "DateCreated"
        case badgeName = "BadgeName"
        case displayOrder = "DisplayOrder"
        case memAddr = "MemAddr"
        case type = "Type"
        case dateEarnedHardcore = "DateEarnedHardcore"
        case dateEarned = "DateEarned"
    }
}
