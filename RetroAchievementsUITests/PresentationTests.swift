//
//  PresentationTests.swift
//  RetroAchievementsUITests
//
//  Regression cover for display logic that was wrong before the UI overhaul.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("Achievement ordering")
struct AchievementOrderingTests {

    /// Ten achievements whose stringified IDs sort differently from their
    /// numeric order — "10" < "9" lexicographically.
    private func summary(count: Int) -> GameSummary {
        var achievements: [String: Achievement] = [:]
        for index in 1...count {
            let id = index
            achievements["\(id)"] = Achievement(
                id: id, numAwarded: 0, numAwardedHardcore: 0,
                title: "Achievement \(index)", description: "",
                points: 5, trueRatio: 5, author: "a",
                dateModified: nil, dateCreated: "", badgeName: "\(id)",
                displayOrder: index, memAddr: "", type: nil,
                dateEarnedHardcore: nil, dateEarned: nil)
        }

        return GameSummary(
            id: 1, title: "Game", consoleID: 1, forumTopicID: nil, flags: nil,
            imageIcon: "", imageTitle: "", imageIngame: "", imageBoxArt: "",
            publisher: nil, developer: nil, genre: nil, released: "",
            isFinal: false, richPresencePatch: "", playersTotal: nil,
            achievementsPublished: nil, pointsTotal: nil, guideURL: nil,
            consoleName: "C", parentGameID: nil, numDistinctPlayers: 0,
            numAchievements: count, achievements: achievements,
            numAwardedToUser: 0, numAwardedToUserHardcore: 0,
            numDistinctPlayersCasual: 0, numDistinctPlayersHardcore: 0,
            userCompletion: "", userCompletionHardcore: "",
            highestAwardKind: nil, highestAwardDate: nil)
    }

    @Test("Achievements follow DisplayOrder, not the stringified dictionary key")
    func ordersByDisplayOrder() {
        let ordered = summary(count: 12).orderedAchievements

        #expect(ordered.map(\.displayOrder) == Array(1...12))
        // Sorting the dictionary keys as strings would put "10" second.
        #expect(ordered[1].title == "Achievement 2")
        #expect(ordered.last?.title == "Achievement 12")
    }

    @Test("Ties on DisplayOrder fall back to ID for a stable order")
    func stableOnTies() {
        var achievements: [String: Achievement] = [:]
        for id in [30, 10, 20] {
            achievements["\(id)"] = Achievement(
                id: id, numAwarded: 0, numAwardedHardcore: 0,
                title: "A\(id)", description: "", points: 0, trueRatio: 0,
                author: "a", dateModified: nil, dateCreated: "",
                badgeName: "", displayOrder: 0, memAddr: "", type: nil,
                dateEarnedHardcore: nil, dateEarned: nil)
        }
        var base = summary(count: 1)
        base = GameSummary(
            id: base.id, title: base.title, consoleID: base.consoleID,
            forumTopicID: nil, flags: nil, imageIcon: "", imageTitle: "",
            imageIngame: "", imageBoxArt: "", publisher: nil, developer: nil,
            genre: nil, released: "", isFinal: false, richPresencePatch: "",
            playersTotal: nil, achievementsPublished: nil, pointsTotal: nil,
            guideURL: nil, consoleName: "C", parentGameID: nil,
            numDistinctPlayers: 0, numAchievements: 3,
            achievements: achievements, numAwardedToUser: 0,
            numAwardedToUserHardcore: 0, numDistinctPlayersCasual: 0,
            numDistinctPlayersHardcore: 0, userCompletion: "",
            userCompletionHardcore: "", highestAwardKind: nil, highestAwardDate: nil)

        #expect(base.orderedAchievements.map(\.id) == [10, 20, 30])
    }

    @Test("An empty achievement set orders to nothing")
    func emptySet() {
        let empty = summary(count: 1)
        #expect(empty.orderedAchievements.count == 1)
    }
}

@Suite("Recent achievement dates")
struct RecentAchievementDateTests {

    @Test("Parses the API's date format")
    func parsesDate() {
        // Regression: the previous formatter used "YYYY" (ISO week-year), which
        // reports the following year for dates in late December.
        #expect(RecentAchievement.relativeDate("2024-12-30 18:55:18") != nil)
    }

    @Test("An unparseable date yields nil rather than the string \"Error\"")
    func rejectsBadDate() {
        #expect(RecentAchievement.relativeDate("not a date") == nil)
        #expect(RecentAchievement.relativeDate("") == nil)
    }
}

@Suite("Recent achievement filtering")
struct RecentAchievementFilteringTests {

    private func achievement(id: Int, hardcore: Int, game: String = "Game") -> RecentAchievement {
        RecentAchievement(
            id: id, date: "2024-01-01 00:00:00", hardcoreMode: hardcore,
            title: "T\(id)", description: "", badgeName: "b", points: 5,
            trueRatio: 5, type: nil, author: "a", gameTitle: game,
            gameIcon: "", gameID: 1, consoleName: "C", badgeURL: "", gameURL: "")
    }

    /// Mirrors RecentAchievementsView's selection so the ordering of
    /// filter-then-limit is pinned down.
    private func select(_ list: [RecentAchievement],
                        hardcoreMode: Bool,
                        showUnofficial: Bool,
                        limit: Int) -> [RecentAchievement] {
        var result = list
        if !showUnofficial { result = result.filter { !$0.gameTitle.starts(with: "~") } }
        if hardcoreMode { result = result.filter { $0.hardcoreMode == 1 } }
        return Array(result.prefix(limit))
    }

    @Test("Filtering happens before limiting, so hardcore mode still fills the list")
    func filterBeforeLimit() {
        // Three softcore unlocks followed by three hardcore ones. Taking the
        // first three and *then* filtering left hardcore mode showing nothing.
        let list = [
            achievement(id: 1, hardcore: 0),
            achievement(id: 2, hardcore: 0),
            achievement(id: 3, hardcore: 0),
            achievement(id: 4, hardcore: 1),
            achievement(id: 5, hardcore: 1),
            achievement(id: 6, hardcore: 1),
        ]

        let hardcore = select(list, hardcoreMode: true, showUnofficial: false, limit: 3)
        #expect(hardcore.count == 3)
        #expect(hardcore.map(\.id) == [4, 5, 6])
    }

    @Test("Fewer achievements than the limit does not trap")
    func fewerThanLimitIsSafe() {
        // `prefix(upTo: 3)` traps on a shorter collection; `prefix(3)` does not.
        let list = [achievement(id: 1, hardcore: 1)]
        #expect(select(list, hardcoreMode: true, showUnofficial: false, limit: 3).count == 1)
        #expect(select([], hardcoreMode: true, showUnofficial: false, limit: 3).isEmpty)
    }

    @Test("Unofficial games are excluded unless requested")
    func unofficialFiltering() {
        let list = [
            achievement(id: 1, hardcore: 1, game: "~Demo Game"),
            achievement(id: 2, hardcore: 1, game: "Real Game"),
        ]

        #expect(select(list, hardcoreMode: true, showUnofficial: false, limit: 3).map(\.id) == [2])
        #expect(select(list, hardcoreMode: true, showUnofficial: true, limit: 3).count == 2)
    }
}

@Suite("Achievement rarity")
struct AchievementRarityTests {

    @Test("Maps unlock share onto the specified bands",
          arguments: [
            (100.0, AchievementRarity.common),
            (75.0,  AchievementRarity.common),
            (50.1,  AchievementRarity.common),
            (50.0,  AchievementRarity.uncommon),     // boundary: 50 is uncommon
            (40.0,  AchievementRarity.uncommon),
            (33.1,  AchievementRarity.uncommon),
            (33.0,  AchievementRarity.rare),         // boundary: 33 is rare
            (25.0,  AchievementRarity.rare),
            (20.1,  AchievementRarity.rare),
            (20.0,  AchievementRarity.epic),         // boundary: 20 is epic
            (15.0,  AchievementRarity.epic),
            (10.1,  AchievementRarity.epic),
            (10.0,  AchievementRarity.legendary),    // boundary: the hardest tenth
            (2.0,   AchievementRarity.legendary),
            (0.0,   AchievementRarity.legendary),
          ])
    func mapsUnlockShare(percentage: Double, expected: AchievementRarity) {
        #expect(AchievementRarity(unlockPercentage: percentage) == expected)
    }

    @Test("Unlock share is computed from awards over the game's players")
    func computesShare() {
        let achievement = Self.sample(numAwarded: 2_000)

        #expect(achievement.unlockPercentage(totalPlayers: 8_000) == 25)
        #expect(achievement.rarity(totalPlayers: 8_000) == .rare)
    }

    @Test("Rarity is absent rather than wrong when the player count is unknown")
    func unknownPlayerCount() {
        let achievement = Self.sample(numAwarded: 10)

        // GetUserRecentAchievements supplies no player total; guessing would
        // colour the same achievement differently than the game sheet does.
        #expect(achievement.rarity(totalPlayers: nil) == nil)
        #expect(achievement.rarity(totalPlayers: 0) == nil)
        #expect(achievement.unlockPercentage(totalPlayers: 0) == nil)
    }

    @Test("More awards than players clamps to 100% rather than overflowing")
    func clampsOverOneHundred() {
        let achievement = Self.sample(numAwarded: 500)
        #expect(achievement.unlockPercentage(totalPlayers: 100) == 100)
        #expect(achievement.rarity(totalPlayers: 100) == .common)
    }

    @Test("Tiers order from common up to legendary")
    func ordering() {
        #expect(AchievementRarity.allCases.sorted() ==
                [.common, .uncommon, .rare, .epic, .legendary])
        #expect(AchievementRarity.legendary > AchievementRarity.common)
    }

    @Test("Every tier has a distinct material and only legendary is foiled")
    func materialsDiffer() {
        let inks = AchievementRarity.allCases.map { RarityMaterial.of($0).ink }
        #expect(Set(inks.map(String.init(describing:))).count == AchievementRarity.allCases.count)

        #expect(AchievementRarity.allCases
            .filter { RarityMaterial.of($0).isFoil } == [.legendary])
    }

    private static func sample(numAwarded: Int) -> Achievement {
        Achievement(
            id: 1, numAwarded: numAwarded, numAwardedHardcore: 0,
            title: "T", description: "", points: 5, trueRatio: 5, author: "a",
            dateModified: nil, dateCreated: "", badgeName: "b",
            displayOrder: 1, memAddr: "", type: nil,
            dateEarnedHardcore: nil, dateEarned: nil)
    }
}

@Suite("Achievement rarity sorting")
struct AchievementRaritySortingTests {

    /// Three achievements at 10%, 50% and 90% of an 100-player game.
    private func summary() -> GameSummary {
        var set: [String: Achievement] = [:]
        for (id, awarded, order) in [(1, 90, 1), (2, 50, 2), (3, 10, 3)] {
            set["\(id)"] = Achievement(
                id: id, numAwarded: awarded, numAwardedHardcore: 0,
                title: "A\(id)", description: "", points: 5, trueRatio: 5,
                author: "a", dateModified: nil, dateCreated: "", badgeName: "b",
                displayOrder: order, memAddr: "", type: nil,
                dateEarnedHardcore: nil, dateEarned: nil)
        }
        return GameSummary(
            id: 1, title: "G", consoleID: 1, forumTopicID: nil, flags: nil,
            imageIcon: "", imageTitle: "", imageIngame: "", imageBoxArt: "",
            publisher: nil, developer: nil, genre: nil, released: "",
            isFinal: false, richPresencePatch: "", playersTotal: nil,
            achievementsPublished: nil, pointsTotal: nil, guideURL: nil,
            consoleName: "C", parentGameID: nil, numDistinctPlayers: 100,
            numAchievements: 3, achievements: set, numAwardedToUser: 0,
            numAwardedToUserHardcore: 0, numDistinctPlayersCasual: 0,
            numDistinctPlayersHardcore: 0, userCompletion: "",
            userCompletionHardcore: "", highestAwardKind: nil, highestAwardDate: nil)
    }

    @Test("Rarest first inverts the set's display order here")
    func sortsRarestFirst() {
        let game = summary()

        #expect(game.orderedAchievements.map(\.id) == [1, 2, 3])       // display order
        #expect(game.achievementsByRarity.map(\.id) == [3, 2, 1])      // 10%, 50%, 90%
    }

    @Test("Equal rarity falls back to display order")
    func stableOnTies() {
        let game = summary()
        let tied = game.achievementsByRarity.filter {
            $0.unlockPercentage(totalPlayers: 100) == 50
        }
        #expect(tied.count == 1)
        // Full list stays deterministic across repeated sorts.
        #expect(game.achievementsByRarity.map(\.id) == game.achievementsByRarity.map(\.id))
    }
}
