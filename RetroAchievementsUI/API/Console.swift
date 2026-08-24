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

class Consoles {
    var consoles: [Console] = []
    var consolesSortedByKind: [ConsoleByManuFacturer] = []
    var aConsoles:    ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Atari", consoleIDList: [13, 17, 25, 51, 77])
    var neConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "NEC", consoleIDList: [8, 47, 49, 76])
    var niConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Nintendo", consoleIDList: [2, 3, 4, 5, 6, 7, 16, 18, 19, 24, 28, 78])
    var seConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Sega", consoleIDList: [1, 9, 10, 11, 15, 33, 39, 40])
    var snConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "SNK", consoleIDList: [14, 56])
    var soConsoles:   ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Sony", consoleIDList: [12, 21, 41])
    var otherConoles: ConsoleByManuFacturer = ConsoleByManuFacturer(id: "Other", consoleIDList: [23, 27, 29, 37, 38, 43, 44, 45, 46, 53, 57, 63, 69, 71, 72, 73, 74, 75, 80, 102])
    
    /// Index for O(1) lookups. The previous implementation ran a linear filter
    /// inside a sort comparator, making startup sorting O(n² log n).
    private var consolesByID: [Int: Console] = [:]

    init(consoles: [Console]){
        self.consoles = consoles
        self.consolesByID = Dictionary(consoles.map { ($0.id, $0) },
                                       uniquingKeysWith: { first, _ in first })

        // Drop IDs the API did not return before sorting. These lists are
        // hardcoded, so a console being retired or renamed upstream used to
        // crash on the force-unwrap in getConsoleDataByID.
        func prepare(_ group: ConsoleByManuFacturer) -> ConsoleByManuFacturer {
            var group = group
            group.consoleIDList = group.consoleIDList
                .compactMap { consolesByID[$0] }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
                .map(\.id)
            return group
        }

        aConsoles = prepare(aConsoles)
        neConsoles = prepare(neConsoles)
        niConsoles = prepare(niConsoles)
        seConsoles = prepare(seConsoles)
        snConsoles = prepare(snConsoles)
        soConsoles = prepare(soConsoles)
        otherConoles = prepare(otherConoles)

        // snConsoles (SNK) was missing from this list, so SNK consoles never
        // appeared in the Consoles tab.
        consolesSortedByKind = [aConsoles, neConsoles, niConsoles, seConsoles,
                                snConsoles, soConsoles, otherConoles]
            .filter { !$0.consoleIDList.isEmpty }
    }

    func getConsoleDataByID(consoleID: Int) -> Console? {
        consolesByID[consoleID]
    }
}
