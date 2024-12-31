//
//  Profile.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation

struct Profile: Codable {
    let user: String
    let userPic: String
    let memberSince: String
    let richPresenceMsg: String?
    let lastGameID: Int
    let contribCount: Int
    let contribYield: Int
    let totalPoints: Int
    let totalSoftcorePoints: Int
    let totalTruePoints: Int
    let permissions: Int
    let untracked: Int
    let id: Int
    let userWallActive: Bool
    let motto: String
    
    enum CodingKeys: String, CodingKey {
        case user = "User"
        case userPic = "UserPic"
        case memberSince = "MemberSince"
        case richPresenceMsg = "RichPresenceMsg"
        case lastGameID = "LastGameID"
        case contribCount = "ContribCount"
        case contribYield = "ContribYield"
        case totalPoints = "TotalPoints"
        case totalSoftcorePoints = "TotalSoftcorePoints"
        case totalTruePoints = "TotalTruePoints"
        case permissions = "Permissions"
        case untracked = "Untracked"
        case id = "ID"
        case userWallActive = "UserWallActive"
        case motto = "Motto"
    }
}
