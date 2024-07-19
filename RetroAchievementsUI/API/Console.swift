//
//  Console.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation

struct Console: Codable, Identifiable {
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

struct ConsoleByManuFacturer: Codable, Identifiable {
    let id: String
    var consoleIDList: [Int]
}

struct ConsoleGameInfo: Codable, Identifiable {
    let title: String
    let id: Int
    let consoleID: Int
    let consoleName: String
    let imageIcon: String
    let numAchievements: Int
    let numLeaderboards: Int
    let points: Int
    let dateModified: String
    let forumTopicID: Int?
    let hashes: [String]?

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
        case hashes = "Hashes"
    }
}


class Consoles {
    var consoles: [Console] = []
    var consolesSortedByKind: [ConsoleByManuFacturer] = []
    var aConsoles:    ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Atari", consoleIDList: [13, 17, 25, 51, 77])
    var neConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "NEC", consoleIDList: [8, 47, 49, 76])
    var niConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Nintendo", consoleIDList: [2, 3, 4, 5, 6, 7, 16, 18, 24, 28, 78])
    var seConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Sega", consoleIDList: [1, 9, 10, 11, 15, 33, 39, 40])
    var snConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "SNK", consoleIDList: [14, 56])
    var soConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Sony", consoleIDList: [12, 21, 41])
    var otherConoles: ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Other", consoleIDList: [23, 27, 29, 37, 38, 43, 44, 45, 46, 53, 57, 63, 69, 71, 72, 73, 74, 75, 80, 102])
    
    init(consoles: [Console]){
        self.consoles = consoles
        
        aConsoles.consoleIDList = aConsoles.consoleIDList.sorted {
            getConsoleDataByID(consoleID: $0).name.lowercased() < getConsoleDataByID(consoleID: $1).name.lowercased()
        }
        
        neConsoles.consoleIDList = neConsoles.consoleIDList.sorted {
            getConsoleDataByID(consoleID: $0).name.lowercased() < getConsoleDataByID(consoleID: $1).name.lowercased()
        }
        
        niConsoles.consoleIDList = niConsoles.consoleIDList.sorted {
            getConsoleDataByID(consoleID: $0).name.lowercased() < getConsoleDataByID(consoleID: $1).name.lowercased()
        }
        
        seConsoles.consoleIDList = seConsoles.consoleIDList.sorted {
            getConsoleDataByID(consoleID: $0).name.lowercased() < getConsoleDataByID(consoleID: $1).name.lowercased()
        }
        
        snConsoles.consoleIDList = snConsoles.consoleIDList.sorted {
            getConsoleDataByID(consoleID: $0).name.lowercased() < getConsoleDataByID(consoleID: $1).name.lowercased()
        }
        
        soConsoles.consoleIDList = soConsoles.consoleIDList.sorted {
            getConsoleDataByID(consoleID: $0).name.lowercased() < getConsoleDataByID(consoleID: $1).name.lowercased()
        }
        
        otherConoles.consoleIDList = otherConoles.consoleIDList.sorted {
            getConsoleDataByID(consoleID: $0).name.lowercased() < getConsoleDataByID(consoleID: $1).name.lowercased()
        }
        
        consolesSortedByKind = [aConsoles, neConsoles, niConsoles, seConsoles, soConsoles, otherConoles]
    }
    
    func getConsoleDataByID(consoleID: Int) -> Console {
        return self.consoles.filter { $0.id == consoleID}.first!
    }
}
