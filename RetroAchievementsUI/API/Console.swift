//
//  Console.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation

struct Console: Codable {
    let id: Int
    let name: String
    let iconURL: String
    let active: Bool
    let isGameSystem: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
        case iconURL = "IconURL"
        case active = "Active"
        case isGameSystem = "IsGameSystem"
    }
}
